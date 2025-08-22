# Secure Launcher - Android Kiosk Uygulaması

Android cihazları kiosk modunda çalıştırmak için tasarlanmış güvenli launcher uygulaması.

## Özellikler

✅ **Kiosk Modu**: Cihazı belirli uygulamalarla sınırlandır
✅ **Şifre Koruması**: SHA-256 + salt ile güvenli şifre sistemi
✅ **Device Owner Desteği**: Tam kiosk özellikleri için Device Owner modu
✅ **HOME Launcher**: Home tuşuna basıldığında bu uygulama açılır
✅ **İzinli Uygulama Yönetimi**: Hangi uygulamaların açılabileceğini kontrol edin
✅ **Material 3 Tasarım**: Modern Android UI

## Kurulum

### 1. APK Kurulumu
```bash
flutter build apk --release
adb install build/app/outputs/flutter-apk/app-release.apk
```

### 2. Device Owner Ayarlama (Önerilen)

Tam kiosk özelliklerini kullanmak için uygulamayı Device Owner yapmak gerekir:

```bash
# Cihazda tüm Google hesaplarını çıkarın
# Fabrika ayarlarına sıfırlama yapın (opsiyonel ama önerilir)

# Device Owner olarak ayarlayın
adb shell dpm set-device-owner com.erkayteknoloji.securelauncher/.MyDeviceAdminReceiver
```

**Not**: Device Owner ayarı yalnızca:
- Cihazda hiç Google hesabı yokken
- Genellikle fabrika ayarları sonrasında yapılabilir

### 3. Alternatif - Manuel Ekran Sabitleme

Device Owner olamıyorsanız, Android'in yerleşik ekran sabitleme özelliğini kullanabilirsiniz:

1. **Ayarlar → Güvenlik → Ekran sabitleme**'yi etkinleştirin
2. Uygulamayı açın ve "Kiosk Moduna Gir" butonuna basın
3. Sistem ekran sabitleme dialog'unu onaylayın

## Kullanım

### İlk Kurulum
1. Uygulamayı açın
2. Kiosk şifresini belirleyin
3. İzin vermek istediğiniz uygulamaları seçin

### Kiosk Moduna Geçiş
1. Sağ üstteki kilit ikonuna tıklayın
2. "Kiosk Moduna Gir" butonuna basın
3. Sistem onayını verin (Device Owner değilseniz)

### Kiosk Modundan Çıkış
1. Sağ üstteki kilit ikonuna tıklayın
2. Şifrenizi girin
3. "Tamam" butonuna basın

## Geliştirme

### Gereksinimler
- Flutter SDK
- Android SDK
- Android Studio veya VS Code

### Çalıştırma
```bash
flutter pub get
flutter run
```

### Build
```bash
# Debug APK
flutter build apk

# Release APK
flutter build apk --release
```

## Güvenlik

- Şifreler SHA-256 + salt ile hash'lenir
- Düz metin şifre saklanmaz
- Platform kontrolü ile sadece Android'de çalışır

## Sorun Giderme

### "Device Owner değil" Uyarısı
- Normal bir durumdur
- Manuel ekran sabitleme özelliklerini kullanabilirsiniz
- Tam özellikler için Device Owner kurulumu gerekir

### Kiosk Modu Çalışmıyor
1. Android sürümünüzün desteklediğini kontrol edin (API 21+)
2. Device Owner kurulumunu deneyin
3. Manuel ekran sabitleme ayarlarını kontrol edin

### Uygulamalar Görünmüyor
1. QUERY_ALL_PACKAGES izni verilmiş mi kontrol edin
2. Android 11+ cihazlarda ekstra izinler gerekebilir

## Lisans

Bu proje MIT lisansı altında dağıtılmaktadır.
