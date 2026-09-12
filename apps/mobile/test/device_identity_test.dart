import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import '../lib/identity/app_auth.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'iPhone login sends the backend device contract and persists installation',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      FlutterSecureStorage.setMockInitialValues({});
      PackageInfo.setMockInitialValues(
        appName: 'Bliss',
        packageName: 'com.dddcreate.bliss.dev',
        version: '1.0.0',
        buildNumber: '1',
        buildSignature: '',
      );
      const channel = MethodChannel('dev.fluttercommunity.plus/device_info');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            channel,
            (_) async => {
              'name': 'iPhone',
              'systemName': 'iOS',
              'systemVersion': '18.1',
              'model': 'iPhone',
              'modelName': 'iPhone 13 mini',
              'localizedModel': 'iPhone',
              'freeDiskSize': 100,
              'totalDiskSize': 200,
              'isPhysicalDevice': true,
              'physicalRamSize': 4,
              'availableRamSize': 2,
              'isiOSAppOnMac': false,
              'utsname': {
                'sysname': 'Darwin',
                'nodename': 'iPhone',
                'release': '1',
                'version': '1',
                'machine': 'iPhone14,4',
              },
            },
          );
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      String? installation;
      final auth = AppAuth(
        product: 'split',
        baseUrl: 'https://example.test',
        client: MockClient((request) async {
          final device = jsonDecode(request.body)['device'] as Map;
          expect(device['platform'], 'ios');
          expect(device['model'], 'iPhone14,4');
          expect(device['app_version'], '1.0.0+1');
          expect(device['id'], matches(RegExp(r'^[0-9a-f-]{36}$')));
          installation = device['id'];
          return http.Response(
            jsonEncode({
              'access_token': 'access',
              'refresh_token': 'refresh',
              'expires_in': 600,
              'user': {'id': 'user'},
            }),
            200,
          );
        }),
      );
      addTearDown(auth.dispose);
      await auth.login('test@example.test', 'test-password');
      expect(
        await auth.storage.read(key: 'split.installation.id.v1'),
        installation,
      );
      expect(auth.session, isNotNull);
    },
  );
}
