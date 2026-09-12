import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DeviceIdentity {
  static Future<Map<String, dynamic>>? _pending;
  static Future<Map<String, dynamic>> current() => _pending ??= _load();
  static Future<Map<String, dynamic>> _load() async {
    const storage = FlutterSecureStorage();
    const key = 'split.installation.id.v1';
    var id = await storage.read(key: key);
    if (id == null) {
      final random = Random.secure();
      final bytes = List<int>.generate(16, (_) => random.nextInt(256));
      bytes[6] = (bytes[6] & 15) | 64;
      bytes[8] = (bytes[8] & 63) | 128;
      final h = bytes.map((v) => v.toRadixString(16).padLeft(2, '0')).join();
      id =
          '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
      await storage.write(key: key, value: id);
    }
    final platform = kIsWeb ? 'web' : defaultTargetPlatform.name.toLowerCase();
    var name = platform, model = platform;
    final info = DeviceInfoPlugin();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      final d = await info.iosInfo;
      name = d.name;
      model = d.utsname.machine;
    } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final d = await info.androidInfo;
      name = '${d.manufacturer} ${d.model}';
      model = d.model;
    }
    final app = await PackageInfo.fromPlatform();
    return {
      'id': id,
      'platform': platform,
      'name': name,
      'model': model,
      'app_version': '${app.version}+${app.buildNumber}',
    };
  }
}
