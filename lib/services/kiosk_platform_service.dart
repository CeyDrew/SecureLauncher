import 'dart:io';
import 'package:flutter/services.dart';

class LaunchableApp {
  final String packageName;
  final String appName;
  final Uint8List iconBytes;

  const LaunchableApp({
    required this.packageName,
    required this.appName,
    required this.iconBytes,
  });

  factory LaunchableApp.fromMap(Map<String, dynamic> map) {
    return LaunchableApp(
      packageName: map['packageName'] as String,
      appName: map['appName'] as String,
      iconBytes: Uint8List.fromList(List<int>.from(map['iconBytes'])),
    );
  }
}

class KioskPlatformService {
  static const MethodChannel _channel = MethodChannel('com.example.kiosk/locktask');

  void _checkPlatform() {
    if (!Platform.isAndroid) {
      throw Exception('Bu uygulama sadece Android cihazlarda çalışır');
    }
  }

  Future<void> startLockTask() async {
    _checkPlatform();
    try {
      await _channel.invokeMethod('startLockTask');
    } catch (e) {
      throw Exception('Kiosk modu başlatılamadı: $e');
    }
  }

  Future<void> stopLockTask() async {
    _checkPlatform();
    try {
      await _channel.invokeMethod('stopLockTask');
    } catch (e) {
      throw Exception('Kiosk modundan çıkılamadı: $e');
    }
  }

  Future<bool> isLockTaskActive() async {
    _checkPlatform();
    try {
      final result = await _channel.invokeMethod<bool>('isLockTaskActive');
      return result ?? false;
    } catch (e) {
      throw Exception('Kiosk modu durumu kontrol edilemedi: $e');
    }
  }

  Future<bool> setLockTaskPackages(List<String> packages) async {
    _checkPlatform();
    try {
      final result = await _channel.invokeMethod<bool>('setLockTaskPackages', {
        'packages': packages,
      });
      return result ?? false;
    } catch (e) {
      throw Exception('İzinli paketler ayarlanamadı: $e');
    }
  }

  Future<bool> isDeviceOwner() async {
    _checkPlatform();
    try {
      final result = await _channel.invokeMethod<bool>('isDeviceOwner');
      return result ?? false;
    } catch (e) {
      throw Exception('Device Owner durumu kontrol edilemedi: $e');
    }
  }

  Future<bool> launchApp(String packageName) async {
    _checkPlatform();
    try {
      final result = await _channel.invokeMethod<bool>('launchApp', {
        'packageName': packageName,
      });
      return result ?? false;
    } catch (e) {
      throw Exception('Uygulama başlatılamadı: $e');
    }
  }

  Future<List<LaunchableApp>> getLaunchableApps() async {
    _checkPlatform();
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('getLaunchableApps');
      if (result == null) return [];

      return result
          .map((app) => LaunchableApp.fromMap(Map<String, dynamic>.from(app)))
          .toList();
    } catch (e) {
      throw Exception('Uygulama listesi alınamadı: $e');
    }
  }

  Future<bool> shouldAutoStartKiosk() async {
    _checkPlatform();
    try {
      final result = await _channel.invokeMethod<bool>('shouldAutoStartKiosk');
      return result ?? false;
    } catch (e) {
      throw Exception('Auto start kontrolü yapılamadı: $e');
    }
  }

  Future<bool> verifyMasterKey(String masterKey) async {
    _checkPlatform();
    try {
      final result = await _channel.invokeMethod<bool>('verifyMasterKey', {
        'masterKey': masterKey,
      });
      return result ?? false;
    } catch (e) {
      throw Exception('Master key doğrulanamadı: $e');
    }
  }

  Future<bool> uninstallApp() async {
    _checkPlatform();
    try {
      final result = await _channel.invokeMethod<bool>('uninstallApp');
      return result ?? false;
    } catch (e) {
      throw Exception('Uygulama kaldırılamadı: $e');
    }
  }
}