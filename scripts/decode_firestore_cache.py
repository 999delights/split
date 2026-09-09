"""Decode a LevelDB hex dump from an offline Firestore cache copy, never live files.
Wire tags match the pinned FirebaseFirestore nanopb document headers in legacy Pods.
This is a cache recovery tool, not a complete Firebase server export.
"""
import json,struct,sys
from datetime import datetime,timezone
from pathlib import Path

def fields(b):
 i=0;out=[]
 def varint():
  nonlocal i
  v=0;s=0
  while True:
   n=b[i];i+=1;v|=(n&127)<<s
   if n<128:return v
   s+=7
   if s>70:raise ValueError('Invalid protobuf')
 while i<len(b):
  tag=varint();wire=tag&7;n=tag>>3
  if wire==0:v=varint()
  elif wire==1:v=b[i:i+8];i+=8
  elif wire==2:size=varint();v=b[i:i+size];i+=size
  elif wire==5:v=b[i:i+4];i+=4
  else:raise ValueError('Unsupported wire type')
  out.append((n,v))
 return out

def mapping(values):
 out={}
 for v in values:
  f=dict(fields(v));out[f[1].decode()]=value(f[2])
 return out

def value(b):
 f=fields(b)
 if len(f)!=1:raise ValueError('Invalid Firestore value')
 n,v=f[0]
 if n==17 or n==5:return v.decode()
 if n==1:return bool(v)
 if n==2:return v if v<2**63 else v-2**64
 if n==3:return struct.unpack('<d',v)[0]
 if n==6:return mapping([v for k,v in fields(v) if k==1])
 if n==9:return [value(v) for k,v in fields(v) if k==1]
 if n==10:
  t=dict(fields(v));return {'seconds':t.get(1,0),'nanos':t.get(2,0)}
 if n==11:return None
 if n==18:return {'bytes_hex':v.hex()}
 raise ValueError('Unsupported value '+str(n))

def decode(path):
 docs=[];pending=0
 for line in Path(path).read_text().splitlines():
  key,raw=line.split(' ',1);key=bytes.fromhex(key)
  if b'remote_document' not in key:continue
  envelope=dict(fields(bytes.fromhex(raw)))
  if 2 not in envelope:continue
  d=fields(envelope[2]);name=dict(d)[1].decode()
  docs.append({'path':name,'fields':mapping([v for k,v in d if k==2]),'committed_mutations':bool(envelope.get(4,0))})
 return {'source':'offline Firestore simulator cache','documents':docs}
if __name__=='__main__':
 data=decode(sys.argv[1]);p=Path(sys.argv[2]);p.write_text(json.dumps(data,indent=2));p.chmod(0o600)
 print('Decoded',len(data['documents']),'cached documents')
