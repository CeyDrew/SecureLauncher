import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'kiosk_platform_service.dart';

class AppUpdateInfo {
  final String version;
  final String url;
  final bool required;
  final String description;

  const AppUpdateInfo({
    required this.version,
    required this.url,
    required this.required,
    required this.description,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    return AppUpdateInfo(
      version: json['version'] as String,
      url: json['url'] as String,
      required: json['required'] as bool,
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'url': url,
      'required': required,
      'description': description,
    };
  }
}

class AppUpdateService {
  final Dio _dio = Dio();
  final KioskPlatformService _platformService = KioskPlatformService();

  /// Güncelleme JSON'ını doğrula
  Future<AppUpdateInfo?> validateUpdateUrl(String url) async {
    try {
      final response = await _dio.get(url);

      if (response.statusCode != 200) {
        throw Exception('URL\'den veri alınamadı: ${response.statusCode}');
      }

      final data = response.data;
      List<dynamic> updates;

      if (data is String) {
        updates = json.decode(data) as List<dynamic>;
      } else if (data is List) {
        updates = data;
      } else {
        throw Exception('Geçersiz JSON formatı');
      }

      if (updates.isEmpty) {
        throw Exception('JSON boş olamaz');
      }

      // İlk güncelleme bilgisini al
      final updateMap = updates[0] as Map<String, dynamic>;

      // Gerekli alanları kontrol et
      if (!updateMap.containsKey('version') ||
          !updateMap.containsKey('url') ||
          !updateMap.containsKey('required') ||
          !updateMap.containsKey('description')) {
        throw Exception('JSON gerekli alanları içermiyor (version, url, required, description)');
      }

      return AppUpdateInfo.fromJson(updateMap);
    } catch (e) {
      if (e is DioException) {
        throw Exception('Bağlantı hatası: ${e.message}');
      }
      rethrow;
    }
  }

  /// Uygulama için güncelleme kontrolü yap
  Future<AppUpdateInfo?> checkForUpdate(String packageName, String updateUrl) async {
    try {
      final updateInfo = await validateUpdateUrl(updateUrl);

      if (updateInfo == null) return null;

      // Hedef uygulamanın mevcut versiyonunu al
      final currentVersion = await _platformService.getPackageVersion(packageName);

      // Eğer uygulama kurulu değilse, güncellemeyi göster (yeni kurulum olarak)
      if (currentVersion == null) {
        return updateInfo;
      }

      print(packageName);
      print(currentVersion);
      print(updateInfo.version);
      print('updateInfo.versionnnnnnnnnnnnnnn');
      // Versiyon karşılaştırması
      if (_isNewerVersion(currentVersion, updateInfo.version)) {
        return updateInfo;
      }

      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Versiyon karşılaştırması (1.0.0 formatında)
  bool _isNewerVersion(String currentVersion, String newVersion) {
    try {
      final current = currentVersion.split('.').map(int.parse).toList();
      final newer = newVersion.split('.').map(int.parse).toList();

      for (int i = 0; i < 3; i++) {
        final currentPart = i < current.length ? current[i] : 0;
        final newerPart = i < newer.length ? newer[i] : 0;

        if (newerPart > currentPart) return true;
        if (newerPart < currentPart) return false;
      }

      return false;
    } catch (e) {
      // Versiyon parse edilemezse, string karşılaştırması yap
      return currentVersion != newVersion;
    }
  }

  /// APK dosyasını indir (progress callback ile)
  /// URL .zip uzantılı olsa bile, dosya aslında APK'dır
  Future<String> downloadApk(
    String url,
    void Function(int received, int total)? onProgress,
  ) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Önce .zip olarak indir
      final zipPath = '${tempDir.path}/update_$timestamp.zip';

      await _dio.download(
        url,
        zipPath,
        onReceiveProgress: onProgress,
      );

      // .zip dosyasını .apk'ya dönüştür (aslında sadece rename)
      final apkPath = '${tempDir.path}/update_$timestamp.apk';
      final zipFile = File(zipPath);
      await zipFile.rename(apkPath);

      return apkPath;
    } catch (e) {
      if (e is DioException) {
        throw Exception('İndirme hatası: ${e.message}');
      }
      rethrow;
    }
  }

  /// APK'yı kur (Android native method channel kullanılacak)
  Future<bool> installApk(String apkPath) async {
    try {
      // Bu metod platform channel üzerinden çağrılacak
      // Şimdilik dosya kontrolü yapalım
      final file = File(apkPath);
      if (!await file.exists()) {
        throw Exception('APK dosyası bulunamadı');
      }

      // TODO: Platform channel ile kurulum yapılacak
      return true;
    } catch (e) {
      rethrow;
    }
  }

  void dispose() {
    _dio.close();
  }
}