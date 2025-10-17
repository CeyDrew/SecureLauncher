import 'package:flutter/material.dart';
import '../models/kiosk_app_model.dart';
import '../services/kiosk_platform_service.dart';
import '../services/app_update_service.dart';
import '../widgets/update_available_dialog.dart';
import '../widgets/download_progress_dialog.dart';

class SettingsScreen extends StatefulWidget {
  final KioskAppModel appModel;

  const SettingsScreen({
    super.key,
    required this.appModel,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final KioskPlatformService _platformService = KioskPlatformService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.settings,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('Ayarlar'),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: widget.appModel,
        builder: (context, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Uygulama Bilgileri',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: const Text('Sürüm'),
                        subtitle: const Text('1.0.0'),
                      ),
                      ListTile(
                        leading: Icon(widget.appModel.isDeviceOwner
                              ? Icons.admin_panel_settings
                              : Icons.admin_panel_settings_outlined,
                        ),
                        title: const Text('Device Owner Durumu'),
                        subtitle: Text(
                          widget.appModel.isDeviceOwner
                              ? 'Aktif - Tam kiosk özelliklerini kullanabilirsiniz'
                              : 'Pasif - Sınırlı kiosk özellikleri',
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: widget.appModel.isDeviceOwner
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.appModel.isDeviceOwner ? 'Aktif' : 'Pasif',
                            style: TextStyle(
                              color: widget.appModel.isDeviceOwner
                                  ? Theme.of(context).colorScheme.onPrimaryContainer
                                  : Theme.of(context).colorScheme.onErrorContainer,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Uygulama Güncelleme',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.update),
                        title: const Text('Güncelleme URL\'si'),
                        subtitle: const Text('SecureLauncher güncellemelerini kontrol etmek için URL'),
                        trailing: const Icon(Icons.edit),
                        onTap: () => _showSelfUpdateUrlDialog(),
                      ),
                      FutureBuilder<String?>(
                        future: widget.appModel.getSelfUpdateUrl(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      snapshot.data!,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton.tonal(
                                    onPressed: () => _checkSelfUpdate(),
                                    child: const Text('Güncelleme Kontrol Et'),
                                  ),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Yönetim İşlemleri',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: Icon(
                          Icons.delete_forever,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        title: const Text('Uygulamanın yönetici yetkilerini kaldır'),
                        subtitle: const Text('Master şifre ile uygulamanın yönetici yetkilerini tamamen kaldır'),
                        onTap: () => _showUninstallDialog(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showUninstallDialog() async {
    final TextEditingController masterKeyController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 8),
            const Text('Uygulamanın yönetici yetkilerini kaldır'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bu işlem geri alınamaz! Uygulamanın yönetici yetkilerini kaldırmak için master şifreyi girin.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: masterKeyController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Master Şifre',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              await _handleUninstall(masterKeyController.text);
            },
            child: const Text('Kaldır'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleUninstall(String masterKey) async {
    if (masterKey.isEmpty) {
      _showSnackBar('Master şifre boş olamaz');
      return;
    }

    try {
      // Master key'i doğrula
      final isValidKey = await _platformService.verifyMasterKey(masterKey);

      if (!isValidKey) {
        _showSnackBar('Yanlış master şifre');
        return;
      }

      // Doğrulama başarılı, uygulamayı kaldır
      final success = await _platformService.uninstallApp();

      if (!success) {
        _showSnackBar('Uygulama kaldırılamadı');
      }
    } catch (e) {
      _showSnackBar('Hata: $e');
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _showSelfUpdateUrlDialog() async {
    final TextEditingController urlController = TextEditingController();
    final currentUrl = await widget.appModel.getSelfUpdateUrl();
    urlController.text = currentUrl ?? '';

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => _SelfUpdateUrlDialog(
        urlController: urlController,
        currentUrl: currentUrl,
        onSave: (url) async {
          // URL'yi doğrula
          _showSnackBar('URL doğrulanıyor...');

          try {
            final updateService = AppUpdateService();
            await updateService.validateUpdateUrl(url);

            // URL geçerli, kaydet
            await widget.appModel.setSelfUpdateUrl(url);

            if (mounted) {
              setState(() {}); // Refresh UI
              _showSnackBar('URL doğrulandı ve kaydedildi');
            }
            return null; // Başarılı
          } catch (e) {
            return 'Geçersiz URL: ${e.toString()}'; // Hata mesajı döndür
          }
        },
        onRemove: () async {
          await widget.appModel.setSelfUpdateUrl('');
          if (mounted) {
            setState(() {}); // Refresh UI
            _showSnackBar('URL kaldırıldı');
          }
        },
      ),
    );
  }

  Future<void> _checkSelfUpdate() async {
    try {
      _showSnackBar('Güncelleme kontrol ediliyor...');

      final updateInfo = await widget.appModel.checkSelfUpdate();

      if (updateInfo == null) {
        _showSnackBar('Güncelleme bulunamadı. Uygulamanız güncel.');
        return;
      }

      if (!mounted) return;

      // Güncelleme mevcut, dialog göster
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return UpdateAvailableDialog(
            appName: 'SecureLauncher',
            updateInfo: updateInfo,
            onUpdate: () async {
              Navigator.of(context).pop();
              await _downloadAndInstallSelfUpdate(updateInfo);
            },
            onCancel: () {
              Navigator.of(context).pop();
            },
          );
        },
      );
    } catch (e) {
      _showSnackBar('Güncelleme kontrolü başarısız: $e');
    }
  }

  Future<void> _downloadAndInstallSelfUpdate(AppUpdateInfo updateInfo) async {
    if (!mounted) return;

    // Progress dialog için GlobalKey kullan
    final dialogKey = GlobalKey<DownloadProgressDialogState>();

    // Progress dialog göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return DownloadProgressDialog(
          key: dialogKey,
          appName: 'SecureLauncher',
          version: updateInfo.version,
        );
      },
    );

    // Dialog'un render edilmesi için kısa bir bekleme
    await Future.delayed(const Duration(milliseconds: 100));

    // İndirme ve kurulumu başlat
    final success = await widget.appModel.downloadAndInstallUpdate(
      updateInfo,
      (received, total) {
        // Progress güncelleme
        dialogKey.currentState?.updateProgress(received, total);
      },
    );

    // Kurulum aşamasına geç
    if (success) {
      dialogKey.currentState?.setInstalling(true);
      // Kurulum bildirimi için 2 saniye bekle
      await Future.delayed(const Duration(seconds: 2));
    }

    if (mounted) {
      Navigator.of(context).pop(); // Progress dialog'u kapat

      if (success) {
        _showSnackBar('SecureLauncher güncellemesi kurulumu başlatıldı');
      } else {
        _showSnackBar('Güncelleme başarısız oldu');
      }
    }
  }
}

// Self Update URL Dialog Widget
class _SelfUpdateUrlDialog extends StatefulWidget {
  final TextEditingController urlController;
  final String? currentUrl;
  final Future<String?> Function(String url) onSave;
  final Future<void> Function() onRemove;

  const _SelfUpdateUrlDialog({
    required this.urlController,
    required this.currentUrl,
    required this.onSave,
    required this.onRemove,
  });

  @override
  State<_SelfUpdateUrlDialog> createState() => _SelfUpdateUrlDialogState();
}

class _SelfUpdateUrlDialogState extends State<_SelfUpdateUrlDialog> {
  bool _isValidating = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Güncelleme URL\'si'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SecureLauncher güncellemelerini kontrol etmek için JSON dosyasının URL\'sini girin.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: widget.urlController,
            enabled: !_isValidating,
            decoration: InputDecoration(
              labelText: 'Güncelleme URL\'si',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.link),
              hintText: 'https://example.com/update.json',
              errorText: _errorMessage,
              errorMaxLines: 3,
            ),
            maxLines: 3,
          ),
          if (_isValidating) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Text(
                  'URL doğrulanıyor...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        if (widget.currentUrl != null && widget.currentUrl!.isNotEmpty)
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: _isValidating
                ? null
                : () async {
                    await widget.onRemove();
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
            child: const Text('Kaldır'),
          ),
        TextButton(
          onPressed: _isValidating ? null : () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: _isValidating ? null : _handleSave,
          child: _isValidating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Kaydet'),
        ),
      ],
    );
  }

  Future<void> _handleSave() async {
    final url = widget.urlController.text.trim();
    if (url.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    // URL'yi doğrula ve kaydet
    final error = await widget.onSave(url);

    if (!mounted) return;

    if (error == null) {
      // Başarılı - dialog'u kapat
      Navigator.of(context).pop();
    } else {
      // Hata var - dialog içinde göster
      setState(() {
        _isValidating = false;
        _errorMessage = error;
      });
    }
  }
}