import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _allowedPackagesKey = 'allowed_packages';

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
}