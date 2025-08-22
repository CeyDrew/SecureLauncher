import 'package:flutter/material.dart';
import '../models/kiosk_app_model.dart';

class SettingsScreen extends StatelessWidget {
  final KioskAppModel appModel;

  const SettingsScreen({
    super.key,
    required this.appModel,
  });

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
        listenable: appModel,
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
                        leading: Icon(appModel.isDeviceOwner
                              ? Icons.admin_panel_settings
                              : Icons.admin_panel_settings_outlined,
                        ),
                        title: const Text('Device Owner Durumu'),
                        subtitle: Text(
                          appModel.isDeviceOwner
                              ? 'Aktif - Tam kiosk özelliklerini kullanabilirsiniz'
                              : 'Pasif - Sınırlı kiosk özellikleri',
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: appModel.isDeviceOwner
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            appModel.isDeviceOwner ? 'Aktif' : 'Pasif',
                            style: TextStyle(
                              color: appModel.isDeviceOwner
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
            ],
          );
        },
      ),
    );
  }
}