import 'package:flutter/material.dart';
import '../models/kiosk_app_model.dart';
import '../services/kiosk_platform_service.dart';

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
}