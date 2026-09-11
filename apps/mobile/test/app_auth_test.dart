import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import '../lib/identity/app_auth.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  test('Concurrent requests share one refresh and store only refresh credentials', () async {
    var calls = 0;
    final auth = AppAuth(product: 'test', baseUrl: 'https://identity.example.test', client: MockClient((req) async {
      calls++;
      expect(req.url.path, '/api/auth/refresh');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      return http.Response(jsonEncode({'access_token':'access','refresh_token':'rotated','expires_in':600,'user':{'id':'one'}}), 200);
    }));
    await auth.storage.write(key: auth.key, value: 'original');
    expect(await Future.wait([auth.accessToken(),auth.accessToken()]), ['access','access']);
    expect(calls,1);
    expect(await auth.storage.read(key:auth.key),'rotated');
    auth.dispose();
  });
  test('Invalid refresh clears session but transport failure preserves it', () async {
    final auth = AppAuth(product:'test',baseUrl:'https://identity.example.test',client:MockClient((_) async => http.Response('{"error":"invalid_session"}',401)));
    await auth.storage.write(key:auth.key,value:'expired');
    expect(await auth.accessToken(),isNull);
    expect(await auth.storage.read(key:auth.key),isNull);
    auth.dispose();
    final offline=AppAuth(product:'test',baseUrl:'https://identity.example.test',client:MockClient((_) async => throw http.ClientException('offline')));
    await offline.storage.write(key:offline.key,value:'keep');
    await expectLater(offline.accessToken(),throwsA(isA<http.ClientException>()));
    expect(await offline.storage.read(key:offline.key),'keep');
    offline.dispose();
  });
  test('Registration response cannot become an authenticated session', () async {
    final auth=AppAuth(product:'test',baseUrl:'https://identity.example.test');
    await expectLater(auth.save({'message':'Confirm your email'}),throwsFormatException);
    expect(auth.session,isNull);
    expect(await auth.storage.read(key:auth.key),isNull);
    auth.dispose();
  });
  test('Restart restores refresh session and logout revokes before clearing', () async {
    final requests = <String>[];
    final client = MockClient((req) async {
      requests.add(req.url.path);
      if (req.url.path.endsWith('/logout')) {
        expect(req.headers['Authorization'], 'Bearer access');
        expect(jsonDecode(req.body)['refresh_token'], 'rotated');
        return http.Response('{}', 200);
      }
      return http.Response(jsonEncode({'access_token':'access','refresh_token':'rotated','expires_in':600,'user':{'id':'one'}}),200);
    });
    final before = AppAuth(product:'test',baseUrl:'https://identity.example.test',client:client);
    await before.save({'access_token':'old','refresh_token':'original','user':{'id':'one'}});
    final restarted = AppAuth(product:'test',baseUrl:before.baseUrl,client:client);
    expect(await restarted.accessToken(), 'access');
    await restarted.logout();
    expect(requests, ['/api/auth/refresh','/api/auth/logout']);
    expect(await restarted.storage.read(key:restarted.key),isNull);
    expect(restarted.session,isNull);
    restarted.dispose();
  });

}
