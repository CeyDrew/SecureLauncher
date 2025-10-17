import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _allowedPackagesKey = 'allowed_packages';
  static const String _kioskModeKey = 'kiosk_mode_enabled';
  static const String _updateUrlsKey = 'app_update_urls';
  static const String _selfUpdateUrlKey = 'self_update_url';

  Future<List<String>> getAllowedPackages() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_allowedPackagesKey) ?? [];
  }

  Future<void> setAllowedPackages(List<String> packages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_allowedPackagesKey, packages);
  }

  Future<void> addAllowedPackage(String packageName) async {
    final packages = await getAllowedPackages();
    if (!packages.contains(packageName)) {
      packages.add(packageName);
      await setAllowedPackages(packages);
    }
  }

  Future<void> removeAllowedPackage(String packageName) async {
    final packages = await getAllowedPackages();
    packages.remove(packageName);
    await setAllowedPackages(packages);
  }

  Future<bool> isPackageAllowed(String packageName) async {
    final packages = await getAllowedPackages();
    return packages.contains(packageName);
  }

  Future<bool> getKioskModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kioskModeKey) ?? false;
  }

  Future<void> setKioskModeEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kioskModeKey, enabled);
  }

  // Güncelleme URL'leri için metodlar
  Future<Map<String, String>> getUpdateUrls() async {
    final prefs = await SharedPreferences.getInstance();
    final urlsJson = prefs.getString(_updateUrlsKey);
    if (urlsJson == null) return {};

    try {
      final Map<String, dynamic> decoded = Map<String, dynamic>.from(
        Uri.splitQueryString(urlsJson)
      );
      return decoded.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      return {};
    }
  }

  Future<void> setUpdateUrl(String packageName, String url) async {
    final urls = await getUpdateUrls();
    urls[packageName] = url;

    final prefs = await SharedPreferences.getInstance();
    final urlsString = urls.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    await prefs.setString(_updateUrlsKey, urlsString);
  }

  Future<void> removeUpdateUrl(String packageName) async {
    final urls = await getUpdateUrls();
    urls.remove(packageName);

    final prefs = await SharedPreferences.getInstance();
    if (urls.isEmpty) {
      await prefs.remove(_updateUrlsKey);
    } else {
      final urlsString = urls.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      await prefs.setString(_updateUrlsKey, urlsString);
    }
  }

  Future<String?> getUpdateUrl(String packageName) async {
    final urls = await getUpdateUrls();
    return urls[packageName];
  }

  // SecureLauncher kendi güncellemesi için URL metodları
  Future<void> setSelfUpdateUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selfUpdateUrlKey, url);
  }

  Future<String?> getSelfUpdateUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selfUpdateUrlKey);
  }

  Future<void> removeSelfUpdateUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selfUpdateUrlKey);
  }
}