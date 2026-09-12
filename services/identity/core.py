"""Per-product identity service. No Firebase or cross-product identity database."""
import hashlib
import json
import secrets
import time
import uuid
from datetime import datetime, timezone
from urllib.parse import urlparse

import jwt
from argon2 import PasswordHasher
from argon2.exceptions import VerificationError
from cryptography.fernet import Fernet
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError

PH = PasswordHasher()
DUMMY_HASH = PH.hash(secrets.token_urlsafe(32))
PROVIDERS = {'google': 'https://accounts.google.com', 'apple': 'https://appleid.apple.com'}


def digest(value):
    return hashlib.sha256(value.encode()).hexdigest()


class AuthError(Exception):
    def __init__(self, code, status=400):
        self.code, self.status = code, status


class Identity:
    def __init__(self, engine, config, verifier=None, clock=time.time):
        self.engine, self.config, self.clock = engine, config, clock
        self.product = config['product']
        if self.product not in ('statz', 'bliss', 'sixth', 'split'):
            raise ValueError('Unknown product')
        self.user_key = 'user_id' if self.product == 'statz' else 'id'
        self.secret = config['secret']
        if len(self.secret) < 32:
            raise ValueError('Identity signing key must have at least 32 characters')
        self.cipher = Fernet(config['email_key'].encode())
        self.issuer = config.get('issuer', self.product + '-auth-' + config['environment'])
        self.audience = config.get('audience', self.product + '-app-' + config['environment'])
        base = urlparse(config['public_url'])
        if base.scheme != 'https' and not (config['environment'] == 'test' and base.hostname == 'localhost'):
            raise ValueError('Identity public URL must use HTTPS')
        self.verifier = verifier or self.verify_provider
        self.jwks = {p: jwt.PyJWKClient(url, timeout=8) for p, url in {
            'google': 'https://www.googleapis.com/oauth2/v3/certs',
            'apple': 'https://appleid.apple.com/auth/keys'}.items()}

    def now(self):
        return int(self.clock())

    def execute(self, c, sql, **params):
        return c.execute(text(sql), params)

    def one(self, c, sql, **params):
        return self.execute(c, sql, **params).mappings().first()

    def user(self, c, uid):
        return self.one(c, f'SELECT {self.user_key} AS id,email,display_name,status FROM app_users WHERE {self.user_key}=:uid', uid=uid)

    def lock_user(self, c, uid):
        suffix = ' FOR UPDATE' if c.dialect.name == 'mysql' else ''
        return self.one(c, f'SELECT {self.user_key} AS id FROM app_users WHERE {self.user_key}=:uid' + suffix, uid=uid)

    def rate(self, c, purpose, key, limit, seconds=900):
        bucket = digest(self.product + purpose + key + str(self.now() // seconds))
        sql = ('INSERT INTO auth_rate_buckets(bucket,attempts,expires_at) VALUES(:b,1,:e) '
               + ('ON DUPLICATE KEY UPDATE attempts=attempts+1' if c.dialect.name == 'mysql'
                  else 'ON CONFLICT(bucket) DO UPDATE SET attempts=attempts+1'))
        self.execute(c, sql, b=bucket, e=self.now()+seconds*2)
        return self.one(c, 'SELECT attempts FROM auth_rate_buckets WHERE bucket=:b', b=bucket)['attempts'] <= limit

    def throttle(self, action, ip, email=''):
        # Separate transaction: failed authentication must not roll back rate limits.
        with self.engine.begin() as c:
            allowed = self.rate(c, action+'ip', ip, 30)
            if email:
                allowed = self.rate(c, action+'email', email, 5) and allowed
        if not allowed:
            raise AuthError('too_many_attempts', 429)

    @staticmethod
    def email(value):
        import re
        if not isinstance(value, str) or len(value) > 254 or not re.fullmatch(r'[^\s@]+@[^\s@]+\.[^\s@]+', value.strip()):
            raise AuthError('invalid_email')
        return value.strip().lower()

    @staticmethod
    def password(value):
        if not isinstance(value, str) or not 12 <= len(value) <= 128:
            raise AuthError('password_length_12_128')
        return value

    def create_user(self, c, email, name):
        uid = str(uuid.uuid4())
        self.execute(c, f'INSERT INTO app_users({self.user_key},email,display_name,status) VALUES(:uid,:email,:name,\'active\')',
                     uid=uid, email=email, name=str(name or self.product.title())[:120])
        return uid

    def event(self, c, uid, kind, provider=None):
        self.execute(c, 'INSERT INTO auth_security_events(user_id,event_type,provider,created_at) VALUES(:u,:k,:p,:t)',
                     u=uid, k=kind, p=provider, t=self.now())

    def enqueue(self, c, uid, email, template, payload, key):
        if not self.config.get('mail_enabled'):
            raise AuthError('email_delivery_not_configured', 503)
        self.execute(c, '''INSERT INTO auth_email_outbox(id,user_id,recipient,template,payload_encrypted,dedupe_key,status,attempts,next_attempt_at,created_at)
            VALUES(:id,:u,:r,:t,:p,:d,'pending',0,:n,:n)''', id=str(uuid.uuid4()), u=uid, r=email,
            t=template, p=self.cipher.encrypt(json.dumps(payload).encode()).decode(), d=key, n=self.now())

    def notify_identity_linked(self, c, uid, provider, identity_key):
        # Called under the account lock, in the same transaction as the new link.
        # Notify an existing verified account contact; never an unverified address.
        user = self.user(c, uid)
        contact = self.one(c, '''SELECT email FROM auth_email_addresses
            WHERE user_id=:u AND verified_at IS NOT NULL
            ORDER BY CASE WHEN email=:e THEN 0 ELSE 1 END, verified_at, email LIMIT 1''',
            u=uid, e=user['email'])
        if not contact:
            return
        key = 'identity-linked:' + uid + ':' + provider + ':' + digest(identity_key)
        if not self.one(c, 'SELECT id FROM auth_email_outbox WHERE dedupe_key=:d', d=key):
            self.enqueue(c, uid, contact['email'], 'identity-linked', {'provider': provider}, key)

    def action(self, c, uid, email, purpose):
        # Supersede previous links; no bearer action token is stored in plaintext.
        self.execute(c, 'UPDATE auth_actions SET consumed_at=:n WHERE user_id=:u AND purpose=:p AND consumed_at IS NULL', n=self.now(),u=uid,p=purpose)
        token = secrets.token_urlsafe(32)
        self.execute(c, 'INSERT INTO auth_actions(token_hash,user_id,email,purpose,expires_at) VALUES(:h,:u,:e,:p,:x)',
                     h=digest(token), u=uid, e=email, p=purpose, x=self.now()+(86400 if purpose == 'verify' else 3600))
        self.enqueue(c, uid, email, 'email-verification' if purpose == 'verify' else 'password-reset',
                     {'token': token, 'purpose': purpose}, 'action:' + digest(token))

    def register(self, email, password, name, ip):
        email = self.email(email)
        self.throttle('register', ip, email)
        password_hash = PH.hash(self.password(password))
        with self.engine.begin() as c:
            existing = self.one(c, 'SELECT user_id FROM auth_email_addresses WHERE email=:e', e=email)
            existing = existing or self.one(c, 'SELECT email FROM app_users WHERE LOWER(email)=:e', e=email)
            if not existing:
                uid = self.create_user(c, email, name)
                self.execute(c, 'INSERT INTO auth_email_addresses(user_id,email,verification_source) VALUES(:u,:e,\'email\')',u=uid,e=email)
                self.execute(c, 'INSERT INTO auth_passwords(user_id,password_hash,changed_at) VALUES(:u,:h,:n)',u=uid,h=password_hash,n=self.now())
                self.action(c, uid, email, 'verify')
                self.event(c, uid, 'registered', 'email')
        return {'message': 'If registration is available, check your email to continue.'}

    def request_email(self, email, purpose, ip):
        email = self.email(email)
        self.throttle(purpose, ip, email)
        with self.engine.begin() as c:
            row = self.one(c, '''SELECT e.*,p.user_id AS password_user FROM auth_email_addresses e
                JOIN auth_passwords p ON p.user_id=e.user_id WHERE e.email=:e''', e=email)
            if row and ((purpose=='verify' and row['verified_at'] is None) or (purpose=='reset' and row['verified_at'] is not None)):
                self.lock_user(c, row['user_id'])
                self.action(c, row['user_id'], email, purpose)
        return {'message': 'If eligible, you will receive an email.'}

    def consume(self, token, purpose, password=None):
        if not isinstance(token, str) or not 20 <= len(token) <= 200:
            raise AuthError('invalid_or_expired_link')
        new_hash = PH.hash(self.password(password)) if purpose == 'reset' else None
        with self.engine.begin() as c:
            suffix = ' FOR UPDATE' if c.dialect.name == 'mysql' else ''
            row = self.one(c, 'SELECT * FROM auth_actions WHERE token_hash=:h' + suffix, h=digest(token))
            if not row or row['purpose'] != purpose or row['consumed_at'] is not None or row['expires_at'] <= self.now():
                raise AuthError('invalid_or_expired_link')
            uid = row['user_id']
            self.lock_user(c, uid)
            if self.user(c,uid)['status']!='active': raise AuthError('account_unavailable',403)
            self.execute(c, 'UPDATE auth_actions SET consumed_at=:n WHERE token_hash=:h',n=self.now(),h=digest(token))
            if purpose == 'verify':
                self.execute(c, 'UPDATE auth_email_addresses SET verified_at=:n,confirmed_at=:n WHERE user_id=:u AND email=:e',n=self.now(),u=uid,e=row['email'])
                if row.get('pending_password_hash'):
                    if self.one(c,'SELECT user_id FROM auth_passwords WHERE user_id=:u',u=uid): raise AuthError('password_already_exists',409)
                    self.execute(c,'INSERT INTO auth_passwords(user_id,password_hash,changed_at) VALUES(:u,:h,:n)',u=uid,h=row['pending_password_hash'],n=self.now())
                    self.event(c,uid,'provider_linked','email')
                    self.notify_identity_linked(c,uid,'email',uid)
                if not self.one(c,'SELECT id FROM auth_email_outbox WHERE dedupe_key=:d',d='welcome:'+uid):
                    self.enqueue(c,uid,row['email'],'welcome',{},'welcome:'+uid)
            else:
                self.execute(c, 'UPDATE auth_passwords SET password_hash=:h,changed_at=:n WHERE user_id=:u',h=new_hash,n=self.now(),u=uid)
                self.execute(c, 'UPDATE auth_sessions SET revoked_at=:n WHERE user_id=:u AND revoked_at IS NULL', n=self.now(),u=uid)
                self.enqueue(c,uid,row['email'],'password-changed',{},'password:'+digest(token))
            self.execute(c,'UPDATE auth_actions SET pending_password_hash=NULL WHERE token_hash=:h',h=digest(token))
            self.event(c,uid,'email_verified' if purpose=='verify' else 'password_changed','email')
        return {'ok': True}

    def login(self, email, password, device, ip):
        email = self.email(email)
        self.throttle('login', ip, email)
        if not isinstance(password,str) or len(password)>128:
            raise AuthError('invalid_credentials',401)
        with self.engine.begin() as c:
            row = self.one(c, '''SELECT p.*,e.verified_at FROM auth_passwords p
              JOIN auth_email_addresses e ON e.user_id=p.user_id WHERE e.email=:e''',e=email)
            try:
                PH.verify(row['password_hash'] if row else DUMMY_HASH, password)
            except VerificationError:
                raise AuthError('invalid_credentials',401) from None
            if not row:
                raise AuthError('invalid_credentials',401)
            if row['verified_at'] is None:
                raise AuthError('email_not_verified',403)
            self.lock_user(c,row['user_id'])
            return self.issue(c,row['user_id'],device,'email')

    def issue(self,c,uid,device,provider,family=None,device_id=None):
        user = self.user(c,uid)
        if not user or user['status']!='active':
            raise AuthError('account_unavailable',403)
        if family is None:
            logged_at=datetime.fromtimestamp(self.now(),timezone.utc).replace(tzinfo=None)
            self.execute(c,f'UPDATE app_users SET last_login_at=:t,last_login_provider=:p WHERE {self.user_key}=:u',t=logged_at,p=provider,u=uid)
            if provider in PROVIDERS:
                self.execute(c,'UPDATE auth_identities SET last_login_at=:t WHERE user_id=:u AND provider=:p',t=logged_at,u=uid,p=provider)
            device_id,device=self.record_device(c,uid,device)
        token = secrets.token_urlsafe(48)
        sid = str(uuid.uuid4())
        self.execute(c, '''INSERT INTO auth_sessions(id,user_id,token_hash,family_id,device_label,provider,expires_at,created_at,device_id)
            VALUES(:id,:u,:h,:f,:d,:p,:x,:n,:di)''',di=device_id,id=sid,u=uid,h=digest(token),f=family or sid,
            d=str(device or 'Mobile')[:120],p=provider,x=self.now()+30*86400,n=self.now())
        claims={'sub':uid,'sid':sid,'typ':'access','iss':self.issuer,'aud':self.audience,'iat':self.now(),'exp':self.now()+600}
        if self.product=='statz':
            legacy=self.one(c,"SELECT subject FROM auth_identities WHERE user_id=:u AND provider='legacy_firebase'",u=uid)
            claims['gid']=legacy['subject'] if legacy else uid
        self.event(c,uid,'session_issued',provider)
        return {'access_token':jwt.encode(claims,self.secret,algorithm='HS256'),'refresh_token':token,
                'expires_in':600,'user':dict(user),'provider':provider}

    def refresh(self, token, device=None):
        replay=False
        with self.engine.begin() as c:
            # Lock the user first so concurrent refreshes cannot create two descendants.
            row=self.one(c,'SELECT user_id FROM auth_sessions WHERE token_hash=:h',h=digest(token))
            if not row: raise AuthError('invalid_session',401)
            self.lock_user(c,row['user_id'])
            suffix=' FOR UPDATE' if c.dialect.name=='mysql' else ''
            row=self.one(c,'SELECT * FROM auth_sessions WHERE token_hash=:h'+suffix,h=digest(token))
            if row['consumed_at'] is not None:
                self.execute(c,'UPDATE auth_sessions SET revoked_at=:n WHERE family_id=:f',n=self.now(),f=row['family_id'])
                replay=True
            elif row['revoked_at'] is not None or row['expires_at']<=self.now():
                raise AuthError('invalid_session',401)
            else:
                self.execute(c,'UPDATE auth_sessions SET consumed_at=:n WHERE id=:s',n=self.now(),s=row['id'])
                device_id=row['device_id']
                if device is not None:
                    device_id,_=self.record_device(c,row['user_id'],device)
                    if row['device_id'] and device_id!=row['device_id']:
                        raise AuthError('device_mismatch',401)
                if device_id:
                    self.execute(c,'UPDATE user_devices SET last_seen_at=:t WHERE id=:d AND user_id=:u',
                        t=datetime.fromtimestamp(self.now(),timezone.utc).replace(tzinfo=None),d=device_id,u=row['user_id'])
                result=self.issue(c,row['user_id'],row['device_label'],row['provider'],row['family_id'],device_id)
        if replay: raise AuthError('session_reuse_detected',401)
        return result

    def authenticate(self, token):
        try:
            claims=jwt.decode(token,self.secret,algorithms=['HS256'],issuer=self.issuer,audience=self.audience,
                options={'require':['sub','sid','exp','iat','iss','aud','typ']})
        except jwt.PyJWTError:
            raise AuthError('invalid_session',401) from None
        if claims['typ']!='access': raise AuthError('invalid_session',401)
        with self.engine.connect() as c:
            row=self.one(c,'SELECT * FROM auth_sessions WHERE id=:s AND user_id=:u',s=claims['sid'],u=claims['sub'])
            user=self.user(c,claims['sub'])
            if not row or row['revoked_at'] is not None or row['expires_at']<=self.now() or not user or user['status']!='active':
                raise AuthError('invalid_session',401)
        return dict(user)

    def logout(self,uid,token,all_devices=False):
        with self.engine.begin() as c:
            if all_devices:
                self.execute(c,'UPDATE auth_sessions SET revoked_at=:n WHERE user_id=:u',n=self.now(),u=uid)
            else:
                row=self.one(c,'SELECT family_id FROM auth_sessions WHERE user_id=:u AND token_hash=:h',u=uid,h=digest(token))
                if row:self.execute(c,'UPDATE auth_sessions SET revoked_at=:n WHERE family_id=:f',n=self.now(),f=row['family_id'])

    def challenge(self, ip):
        self.throttle('challenge',ip)
        nonce=secrets.token_urlsafe(32)
        with self.engine.begin() as c:
            self.execute(c,'INSERT INTO auth_challenges(nonce_hash,expires_at) VALUES(:h,:e)',h=digest(nonce),e=self.now()+300)
        return {'nonce':nonce,'expires_in':300}

    def verify_provider(self, provider, token, nonce):
        if provider not in PROVIDERS: raise AuthError('unknown_provider')
        clients=self.config.get(provider+'_client_ids',[])
        if not clients: raise AuthError(provider+'_not_configured',503)
        try:
            key=self.jwks[provider].get_signing_key_from_jwt(token)
            claims=jwt.decode(token,key.key,algorithms=['RS256'],audience=clients,
                issuer=PROVIDERS[provider],options={'require':['sub','iss','aud','iat','exp']})
            if provider=='apple' and (not nonce or claims.get('nonce')!=digest(nonce)):
                raise AuthError('invalid_provider_token',401)
            return claims
        except AuthError: raise
        except Exception: raise AuthError('invalid_provider_token',401) from None

    def social(self,provider,token,nonce,device,ip,link_user=None):
        self.throttle('social',ip)
        if provider not in PROVIDERS or not isinstance(token,str) or len(token)>16384:
            raise AuthError('invalid_provider_token',401)
        claims=self.verifier(provider,token,nonce)
        subject=claims.get('sub')
        if not isinstance(subject,str) or not 1<=len(subject)<=255: raise AuthError('invalid_provider_token',401)
        verified=claims.get('email_verified') is True or claims.get('email_verified') == 'true'
        if provider=='google' and not verified: raise AuthError('invalid_provider_token',401)
        email=self.email(claims['email']) if claims.get('email') and verified else None
        with self.engine.begin() as c:
            if provider=='apple':
                changed=self.execute(c,'UPDATE auth_challenges SET consumed_at=:n WHERE nonce_hash=:h AND consumed_at IS NULL AND expires_at>:n',n=self.now(),h=digest(nonce or '')).rowcount
                if changed!=1:raise AuthError('invalid_nonce',401)
            row=self.one(c,'SELECT user_id FROM auth_identities WHERE provider=:p AND subject=:s',p=provider,s=subject)
            new_identity = row is None
            if row and link_user and row['user_id']!=link_user:
                raise AuthError('identity_already_linked',409)
            if row:
                uid=row['user_id']
                self.lock_user(c,uid)
                if email:
                    address=self.one(c,'SELECT user_id FROM auth_email_addresses WHERE email=:e',e=email)
                    if address and address['user_id']!=uid: raise AuthError('identity_already_linked',409)
                    if not address:
                        self.execute(c,'INSERT INTO auth_email_addresses(user_id,email,verified_at,verification_source) VALUES(:u,:e,:n,:p)',u=uid,e=email,n=self.now(),p=provider)
                    else:
                        self.execute(c,'UPDATE auth_email_addresses SET verification_source=CASE WHEN verified_at IS NULL THEN :p ELSE verification_source END,verified_at=COALESCE(verified_at,:n) WHERE user_id=:u AND email=:e',p=provider,u=uid,e=email,n=self.now())
            else:
                # Do not attach a new identity by matching an email address.
                existing=self.one(c,'SELECT email FROM app_users WHERE LOWER(email)=:e',e=email) if email else None
                email_owner=self.one(c,'SELECT user_id FROM auth_email_addresses WHERE email=:e',e=email) if email else None
                if link_user:
                    self.lock_user(c,link_user)
                    linked=self.user(c,link_user)
                    if not linked or linked['status']!='active': raise AuthError('account_unavailable',403)
                    if (email_owner and email_owner['user_id']!=link_user) or (existing and linked['email']!=email):
                        raise AuthError('identity_already_linked',409)
                    uid=link_user
                else:
                    if existing or email_owner:raise AuthError('sign_in_to_existing_account_to_link',409)
                    uid=self.create_user(c,email,claims.get('name'))
                extra_id='id,' if self.product!='statz' else ''
                extra_value=':id,' if extra_id else ''
                self.execute(c,f'INSERT INTO auth_identities({extra_id}provider,subject,user_id,email,created_at) VALUES({extra_value}:p,:s,:u,:e,:t)',id=str(uuid.uuid4()),p=provider,s=subject,u=uid,e=email,t=datetime.fromtimestamp(self.now(),timezone.utc).replace(tzinfo=None))
                if email and not self.one(c,'SELECT user_id FROM auth_email_addresses WHERE email=:e',e=email):
                    self.execute(c,'INSERT INTO auth_email_addresses(user_id,email,verified_at,verification_source) VALUES(:u,:e,:n,:p)',u=uid,e=email,n=self.now(),p=provider)
                    if not link_user: self.enqueue(c,uid,email,'welcome',{},'welcome:'+uid)
                if not link_user: self.event(c,uid,'registered',provider)
            if email:
                self.execute(c,'UPDATE auth_email_addresses SET verification_source=CASE WHEN verified_at IS NULL THEN :p ELSE verification_source END,verified_at=COALESCE(verified_at,:n) WHERE user_id=:u AND email=:e',p=provider,n=self.now(),u=uid,e=email)
            self.execute(c,'UPDATE auth_identities SET email=COALESCE(:e,email),email_verified=CASE WHEN :e IS NULL THEN email_verified ELSE :v END WHERE user_id=:u AND provider=:p AND subject=:s',e=email,v=verified,u=uid,p=provider,s=subject)
            if link_user:
                if new_identity:
                    self.event(c,uid,'provider_linked',provider)
                    self.notify_identity_linked(c,uid,provider,subject)
                return {'ok':True}
            return self.issue(c,uid,device,provider)

    def record_device(self,c,uid,device):
        if not isinstance(device,dict): return None, str(device or 'Legacy mobile')[:120]
        try: installation=str(uuid.UUID(device.get('id','')))
        except (ValueError,TypeError,AttributeError): raise AuthError('invalid_device')
        platform=device.get('platform')
        if platform not in ('ios','android','web','macos','windows','linux'): raise AuthError('invalid_device')
        def field(key,limit):
            value=device.get(key,'')
            if not isinstance(value,str) or len(value)>limit: raise AuthError('invalid_device')
            return value
        name=field('name',120) or platform
        model=field('model',120);version=field('app_version',40)
        did=str(uuid.uuid5(uuid.NAMESPACE_URL,uid+':'+installation))
        now=datetime.fromtimestamp(self.now(),timezone.utc).replace(tzinfo=None)
        existing=self.one(c,'SELECT id FROM user_devices WHERE id=:d',d=did)
        params=dict(d=did,u=uid,i=installation,p=platform,n=name,m=model,v=version,t=now)
        if existing:
            self.execute(c,'UPDATE user_devices SET platform=:p,name=:n,model=:m,app_version=:v,last_seen_at=:t,revoked_at=NULL WHERE id=:d AND user_id=:u',**params)
        else:
            self.execute(c,'INSERT INTO user_devices(id,user_id,installation_id,platform,name,model,app_version,last_seen_at) VALUES(:d,:u,:i,:p,:n,:m,:v,:t)',**params)
        return did,name


    def link_email(self,uid,email,password,ip):
        email=self.email(email);self.throttle('link-email',ip,email)
        hashed=PH.hash(self.password(password))
        with self.engine.begin() as c:
            self.lock_user(c,uid)
            if self.one(c,'SELECT user_id FROM auth_passwords WHERE user_id=:u',u=uid):
                raise AuthError('password_already_exists',409)
            owner=self.one(c,'SELECT user_id FROM auth_email_addresses WHERE email=:e',e=email)
            legacy=self.one(c,f'SELECT {self.user_key} FROM app_users WHERE LOWER(email)=:e AND {self.user_key}<>:u',e=email,u=uid)
            if legacy or (owner and owner['user_id']!=uid): raise AuthError('identity_already_linked',409)
            if not owner:
                self.execute(c,"INSERT INTO auth_email_addresses(user_id,email,verification_source) VALUES(:u,:e,'email')",u=uid,e=email)
            self.action(c,uid,email,'verify')
            self.execute(c,"UPDATE auth_actions SET pending_password_hash=:h WHERE user_id=:u AND purpose='verify' AND consumed_at IS NULL",h=hashed,u=uid)
        return {'message':'Check your email to connect email sign-in.'}


    def methods(self, uid):
        with self.engine.connect() as c:
            providers = [r['provider'] for r in self.execute(c, "SELECT DISTINCT provider FROM auth_identities WHERE user_id=:u AND provider IN ('google','apple')", u=uid).mappings()]
            emails = [dict(email=r['email'], verified=r['verified_at'] is not None) for r in self.execute(c, 'SELECT email,verified_at FROM auth_email_addresses WHERE user_id=:u', u=uid).mappings()]
            password = bool(self.one(c, 'SELECT user_id FROM auth_passwords WHERE user_id=:u', u=uid))
        return dict(providers=providers, emails=emails, password_enabled=password)
