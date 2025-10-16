import 'package:flutter/foundation.dart';
import '../services/kiosk_platform_service.dart';
import '../services/password_service.dart';
import '../services/preferences_service.dart';
import '../services/master_key_service.dart';
import '../services/app_update_service.dart';

class KioskAppModel extends ChangeNotifier {
  final KioskPlatformService _platformService = KioskPlatformService();
  final PasswordService _passwordService = PasswordService();
  final PreferencesService _preferencesService = PreferencesService();
  final MasterKeyService _masterKeyService = MasterKeyService();
  final AppUpdateService _updateService = AppUpdateService();

  bool _isKioskMode = false;
  bool _isDeviceOwner = false;
  List<LaunchableApp> _availableApps = [];
  List<String> _allowedPackages = [];
  bool _isLoading = false;
  String? _error;

  bool get isKioskMode => _isKioskMode;
  bool get isDeviceOwner => _isDeviceOwner;
  List<LaunchableApp> get availableApps => _availableApps;
  List<String> get allowedPackages => _allowedPackages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<LaunchableApp> get allowedApps {
    return _availableApps.where((app) => _allowedPackages.contains(app.packageName)).toList();
  }

  Future<void> initialize() async {
    _setLoading(true);
    try {
      await _checkKioskMode();
      await _checkDeviceOwner();
      await _loadAvailableApps();
      await _loadAllowedPackages();

      // Kiosk mode ayarı aktifse ve şu an kiosk modunda değilse, otomatik başlat
      final kioskModeEnabled = await _preferencesService.getKioskModeEnabled();

      if (kioskModeEnabled && !_isKioskMode) {
        // Otomatik olarak kiosk moduna geç
        if (kDebugMode) {
          print('Kiosk mode was enabled but not active, restarting...');
        }
        await Future.delayed(const Duration(milliseconds: 1000)); // UI hazır olana kadar bekle
        await _autoEnterKioskMode();
      }

      _clearError();
    } catch (e) {
      _setError('Başlatma hatası: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> enterKioskMode() async {
    try {
      if (_isDeviceOwner) {
        // İzinli paketlere kendi uygulamamızı da ekleyelim
        final packagesWithSelf = [..._allowedPackages, 'com.erkayteknoloji.securelauncher'];
        await _platformService.setLockTaskPackages(packagesWithSelf);

        // Uygulamayı ana ekran uygulaması yap
        await _platformService.setAsHomeApp();
        if (kDebugMode) {
          print('Set as home app when entering kiosk mode');
        }
      }
      await _platformService.startLockTask();

      // Kiosk mode durumunu kaydet
      await _preferencesService.setKioskModeEnabled(true);

      // Kiosk moduna geçiş için biraz bekle
      await Future.delayed(const Duration(milliseconds: 500));
      await _checkKioskMode();
      _clearError();
    } catch (e) {
      _setError('Kiosk moduna geçilemedi: $e');
    }
  }

  Future<bool> exitKioskMode(String password) async {
    try {
      // Önce normal şifreyi kontrol et
      bool isCorrect = await _passwordService.verifyPassword(password);

      // Eğer normal şifre yanlışsa, master key'i kontrol et
      if (!isCorrect) {
        isCorrect = _masterKeyService.verifyMasterKey(password);

        if (kDebugMode) {
          print('Normal password failed, checking master key: $isCorrect');
        }
      } else {
        if (kDebugMode) {
          print('Normal password verified successfully');
        }
      }

      if (!isCorrect) {
        _setError('Yanlış şifre');
        return false;
      }

      await _platformService.stopLockTask();

      // Ana ekran uygulaması ayarını temizle
      if (_isDeviceOwner) {
        await _platformService.clearHomeApp();
        if (kDebugMode) {
          print('Cleared home app preference when exiting kiosk mode');
        }
      }

      // Kiosk mode durumunu temizle
      await _preferencesService.setKioskModeEnabled(false);

      await _checkKioskMode();
      _clearError();
      return true;
    } catch (e) {
      _setError('Kiosk modundan çıkılamadı: $e');
      return false;
    }
  }

  Future<void> setPassword(String password) async {
    try {
      await _passwordService.setPassword(password);
      _clearError();
    } catch (e) {
      _setError('Şifre ayarlanamadı: $e');
    }
  }

  Future<bool> isPasswordSet() async {
    return await _passwordService.isPasswordSet();
  }

  Future<void> addAllowedApp(String packageName) async {
    try {
      await _preferencesService.addAllowedPackage(packageName);
      await _loadAllowedPackages();

      // Eğer kiosk moddaysak beyaz listeyi güncelle
      if (_isDeviceOwner && _isKioskMode) {
        final packagesWithSelf = [..._allowedPackages, 'com.erkayteknoloji.securelauncher'];
        await _platformService.setLockTaskPackages(packagesWithSelf);
      }

      _clearError();
    } catch (e) {
      _setError('Uygulama eklenemedi: $e');
    }
  }

  Future<void> removeAllowedApp(String packageName) async {
    try {
      await _preferencesService.removeAllowedPackage(packageName);
      await _loadAllowedPackages();

      // Eğer kiosk moddaysak beyaz listeyi güncelle
      if (_isDeviceOwner && _isKioskMode) {
        final packagesWithSelf = [..._allowedPackages, 'com.erkayteknoloji.securelauncher'];
        await _platformService.setLockTaskPackages(packagesWithSelf);
      }

      _clearError();
    } catch (e) {
      _setError('Uygulama çıkarılamadı: $e');
    }
  }


  Future<void> launchApp(String packageName) async {
    try {
      if (kDebugMode) {
        print('Kiosk Mod: $_isKioskMode, Uygulama: $packageName');
        print('İzinli Paketler: $_allowedPackages');
      }

      final success = await _platformService.launchApp(packageName);
      if (!success) {
        _setError('Uygulama başlatılamadı: $packageName');
      } else {
        _clearError();
      }
    } catch (e) {
      _setError('Uygulama başlatma hatası: $e');
    }
  }

  // Güncelleme URL'i yönetimi
  Future<void> setUpdateUrl(String packageName, String url) async {
    try {
      if (url.isEmpty) {
        await _preferencesService.removeUpdateUrl(packageName);
      } else {
        await _preferencesService.setUpdateUrl(packageName, url);
      }
      _clearError();
    } catch (e) {
      _setError('URL kaydedilemedi: $e');
    }
  }

  Future<String?> getUpdateUrl(String packageName) async {
    try {
      return await _preferencesService.getUpdateUrl(packageName);
    } catch (e) {
      return null;
    }
  }

  // Güncelleme kontrolü ve kurulumu
  Future<AppUpdateInfo?> checkAppUpdate(String packageName) async {
    try {
      final updateUrl = await _preferencesService.getUpdateUrl(packageName);
      if (updateUrl == null || updateUrl.isEmpty) {
        return null;
      }

      final updateInfo = await _updateService.checkForUpdate(packageName, updateUrl);
      return updateInfo;
    } catch (e) {
      if (kDebugMode) {
        print('Güncelleme kontrolü hatası: $e');
      }
      return null;
    }
  }

  Future<bool> downloadAndInstallUpdate(
    AppUpdateInfo updateInfo,
    void Function(int, int)? onProgress,
  ) async {
    try {
      // APK'yı indir
      final apkPath = await _updateService.downloadApk(
        updateInfo.url,
        onProgress,
      );

      // APK'yı kur
      final success = await _platformService.installApk(apkPath);
      if (success) {
        _clearError();
      } else {
        _setError('Güncelleme kurulamadı');
      }
      return success;
    } catch (e) {
      _setError('Güncelleme hatası: $e');
      return false;
    }
  }

  Future<void> _checkKioskMode() async {
    _isKioskMode = await _platformService.isLockTaskActive();
    notifyListeners();
  }

  Future<void> _checkDeviceOwner() async {
    _isDeviceOwner = await _platformService.isDeviceOwner();
    print(_isDeviceOwner);
    print('_isDeviceOwneraaaaaa');
    notifyListeners();
  }

  Future<void> _loadAvailableApps() async {
    _availableApps = await _platformService.getLaunchableApps();
    notifyListeners();
  }

  Future<void> _loadAllowedPackages() async {
    _allowedPackages = await _preferencesService.getAllowedPackages();
    notifyListeners();
  }



  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> _autoEnterKioskMode() async {
    try {
      if (kDebugMode) {
        print('Auto entering kiosk mode after boot');
      }

      if (_allowedPackages.isEmpty) {
        _setError('İzinli uygulama bulunamadı, kiosk modu otomatik başlatılamadı');
        return;
      }

      if (_isDeviceOwner) {
        final packagesWithSelf = [..._allowedPackages, 'com.erkayteknoloji.securelauncher'];
        await _platformService.setLockTaskPackages(packagesWithSelf);
      }

      await _platformService.startLockTask();
      await Future.delayed(const Duration(milliseconds: 500));
      await _checkKioskMode();

      if (kDebugMode) {
        print('Kiosk mode auto started successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error auto starting kiosk mode: $e');
      }
      _setError('Otomatik kiosk modu başlatılamadı: $e');
    }
  }
}