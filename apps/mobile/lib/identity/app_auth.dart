import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class AppAuthFailure implements Exception {
  const AppAuthFailure(this.status, this.code, this.message);
  final int status;
  final String code, message;
  @override
  String toString() => message;
}

class AppAuth {
  AppAuth({
    required this.product,
    required this.baseUrl,
    http.Client? client,
    this.googleServerClientId = const String.fromEnvironment(
      'AUTH_GOOGLE_SERVER_CLIENT_ID',
    ),
    this.googleIosClientId = const String.fromEnvironment(
      'AUTH_GOOGLE_IOS_CLIENT_ID',
    ),
  }) : client = client ?? http.Client();
  final String product, baseUrl, googleServerClientId, googleIosClientId;
  final http.Client client;
  final storage = const FlutterSecureStorage();
  Map<String, dynamic>? session;
  Future<String?>? _refreshing;
  String get key => '$product.auth.v2.$baseUrl';
  Future<Map<String, dynamic>> call(
    String path,
    Map<String, dynamic> body, {
    bool authorized = false,
  }) async {
    final token = authorized ? await accessToken() : null;
    final r = await client
        .post(
          Uri.parse('$baseUrl/api/auth$path'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));
    Map<String, dynamic> data;
    try {
      data = Map<String, dynamic>.from(jsonDecode(r.body) as Map);
    } catch (_) {
      throw Exception('Authentication service unavailable. Please retry.');
    }
    if (r.statusCode >= 400) {
      final code = data['error']?.toString() ?? 'unavailable';
      throw AppAuthFailure(r.statusCode, code, _message(code));
    }
    return data;
  }

  static String _message(String code) =>
      const {
        'email_not_verified': 'Confirm your email before signing in.',
        'invalid_credentials': 'Incorrect email or password.',
        'too_many_attempts': 'Too many attempts. Please try again later.',
        'invalid_or_expired_link':
            'This link has expired or was already used. Request a new one.',
        'sign_in_to_existing_account_to_link':
            'Sign in using your existing method before linking this account.',
        'email_delivery_not_configured':
            'Email setup is not complete for this environment.',
        'google_not_configured':
            'Google sign-in is not configured for this environment.',
        'apple_not_configured':
            'Apple sign-in is not configured for this environment.',
        'password_length_12_128':
            'Use a password between 12 and 128 characters.',
      }[code] ??
      'Unable to sign in. Please try again.';
  Future<void> save(Map<String, dynamic> value) async {
    if (value['access_token'] is! String ||
        value['refresh_token'] is! String ||
        value['user'] is! Map) {
      throw const FormatException('Incomplete authentication response');
    }
    await storage.write(key: key, value: value['refresh_token'] as String);
    session = {
      ...value,
      'expires_at':
          DateTime.now().millisecondsSinceEpoch +
          ((value['expires_in'] as num?)?.toInt() ?? 600) * 1000,
    };
  }

  Future<void> login(String email, String password) async {
    await save(
      await call('/login', {
        'email': email.trim(),
        'password': password,
        'device': defaultTargetPlatform.name,
      }),
    );
  }

  Future<void> google() async {
    final serverId = googleServerClientId;
    final iosId = googleIosClientId;
    if (serverId.isEmpty)
      throw Exception('Google client configuration is missing.');
    final google = GoogleSignIn(
      serverClientId: serverId,
      clientId: defaultTargetPlatform == TargetPlatform.iOS && iosId.isNotEmpty ? iosId : null,
    );
    final account = await google.signIn();
    if (account == null) return;
    final credential = await account.authentication;
    if (credential.idToken == null)
      throw Exception('Google did not return an identity token.');
    await save(
      await call('/google', {
        'id_token': credential.idToken,
        'device': defaultTargetPlatform.name,
      }),
    );
  }

  Future<void> apple() async {
    final challenge = await call('/challenge', {});
    final nonce = challenge['nonce'] as String;
    const appleServiceId = String.fromEnvironment('AUTH_APPLE_SERVICE_ID');
    const appleRedirect = String.fromEnvironment('AUTH_APPLE_REDIRECT_URL');
    final webFlow = kIsWeb || defaultTargetPlatform == TargetPlatform.android;
    if (webFlow &&
        (appleServiceId.isEmpty || !appleRedirect.startsWith('https://'))) {
      throw Exception('Apple sign-in is not configured for this platform.');
    }
    final result = await SignInWithApple.getAppleIDCredential(
      webAuthenticationOptions: webFlow
          ? WebAuthenticationOptions(
              clientId: appleServiceId,
              redirectUri: Uri.parse(appleRedirect),
            )
          : null,
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: sha256.convert(utf8.encode(nonce)).toString(),
    );
    if (result.identityToken == null)
      throw Exception('Apple did not return an identity token.');
    await save(
      await call('/apple', {
        'id_token': result.identityToken,
        'nonce': nonce,
        'device': defaultTargetPlatform.name,
      }),
    );
  }

  Future<String?> accessToken() async {
    final current = session;
    if (current != null &&
        (current['expires_at'] as int) >
            DateTime.now().millisecondsSinceEpoch + 30000) {
      return current['access_token'] as String;
    }
    return _refreshing ??= _refresh().whenComplete(() => _refreshing = null);
  }

  Future<String?> _refresh() async {
    final refresh = await storage.read(key: key);
    if (refresh == null) return null;
    // Transport failures retain the refresh token so an offline device does not lose its account.
    try {
      await save(await call('/refresh', {'refresh_token': refresh}));
      return session!['access_token'] as String;
    } on AppAuthFailure catch (e) {
      if (e.status == 401 || e.code == 'account_unavailable') {
        await storage.delete(key: key);
        session = null;
        return null;
      }
      rethrow;
    }
  }

  Future<void> logout({bool allDevices = false}) async {
    final refresh = await storage.read(key: key);
    if (refresh != null)
      await call('/logout', {
        'refresh_token': refresh,
        'all_devices': allDevices,
      }, authorized: true);
    await storage.delete(key: key);
    session = null;
  }

  void dispose() => client.close();
}

class AppAuthScreen extends StatefulWidget {
  const AppAuthScreen({
    super.key,
    required this.auth,
    required this.title,
    required this.onSignedIn,
  });
  final AppAuth auth;
  final String title;
  final VoidCallback onSignedIn;
  @override
  State<AppAuthScreen> createState() => _AppAuthScreenState();
}

class _AppAuthScreenState extends State<AppAuthScreen> {
  final email = TextEditingController(),
      password = TextEditingController(),
      name = TextEditingController();
  bool creating = false, busy = false;
  String? notice;
  Future<void> run(
    Future<void> Function() action, {
    bool signedIn = false,
  }) async {
    if (busy) return;
    setState(() {
      busy = true;
      notice = null;
    });
    try {
      await action();
      if (mounted && signedIn && widget.auth.session != null)
        widget.onSignedIn();
    } catch (e) {
      if (mounted)
        setState(() => notice = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    creating ? 'Create your account' : 'Welcome back',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: busy
                        ? null
                        : () => run(widget.auth.google, signedIn: true),
                    child: const Text('Continue with Google'),
                  ),
                  OutlinedButton(
                    onPressed: busy
                        ? null
                        : () => run(widget.auth.apple, signedIn: true),
                    child: const Text('Continue with Apple'),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'or use your email',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (creating)
                    TextField(
                      controller: name,
                      autofillHints: const [AutofillHints.name],
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: password,
                    obscureText: true,
                    enableSuggestions: false,
                    autocorrect: false,
                    autofillHints: [
                      creating
                          ? AutofillHints.newPassword
                          : AutofillHints.password,
                    ],
                    decoration: const InputDecoration(labelText: 'Password'),
                  ),
                  const SizedBox(height: 16),
                  if (notice != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(notice!),
                    ),
                  if (busy) const Center(child: CircularProgressIndicator()),
                  FilledButton(
                    onPressed: busy
                        ? null
                        : () => run(() async {
                            if (creating) {
                              final r = await widget.auth.call('/register', {
                                'email': email.text.trim(),
                                'password': password.text,
                                'name': name.text.trim(),
                              });
                              if (mounted)
                                setState(
                                  () => notice = r['message'] as String?,
                                );
                            } else {
                              await widget.auth.login(
                                email.text,
                                password.text,
                              );
                            }
                          }, signedIn: !creating),
                    child: Text(creating ? 'Create account' : 'Sign in'),
                  ),
                  TextButton(
                    onPressed: busy
                        ? null
                        : () => setState(() {
                            creating = !creating;
                            notice = null;
                          }),
                    child: Text(
                      creating
                          ? 'Already have an account? Sign in'
                          : 'Create an account',
                    ),
                  ),
                  TextButton(
                    onPressed: busy
                        ? null
                        : () => run(() async {
                            final r = await widget.auth.call(
                              '/forgot-password',
                              {'email': email.text.trim()},
                            );
                            if (mounted)
                              setState(() => notice = r['message'] as String?);
                          }),
                    child: const Text('Forgot password?'),
                  ),
                  TextButton(
                    onPressed: busy
                        ? null
                        : () => run(() async {
                            final r = await widget.auth.call(
                              '/resend-verification',
                              {'email': email.text.trim()},
                            );
                            if (mounted)
                              setState(() => notice = r['message'] as String?);
                          }),
                    child: const Text('Resend confirmation email'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
