import 'package:flutter/material.dart';

import '../models/kiosk_app_model.dart';
import '../widgets/app_grid.dart';
import '../widgets/password_dialog.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final KioskAppModel _appModel;
  bool _showAllApps = false;

  @override
  void initState() {
    super.initState();
    _appModel = KioskAppModel();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _appModel.initialize();
    
    if (!await _appModel.isPasswordSet()) {
      if (mounted) {
        _showSetPasswordDialog();
      }
    }
  }

  Future<void> _showSetPasswordDialog() async {
    final password = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PasswordDialog(
        title: 'Kiosk Şifresi Belirleyin',
        hintText: 'Kiosk modundan çıkmak için kullanılacak şifreyi belirleyin.',
        isConfirmation: true,
      ),
    );

    if (password != null) {
      await _appModel.setPassword(password);
    }
  }

  Future<void> _handleKioskToggle() async {
    if (_appModel.isKioskMode) {
      final password = await showDialog<String>(
        context: context,
        builder: (context) => const PasswordDialog(
          title: 'Kiosk Modundan Çık',
          hintText: 'Kiosk modundan çıkmak için şifrenizi girin.',
        ),
      );

      if (password != null) {
        await _appModel.exitKioskMode(password);
      }
    } else {
      if (_appModel.allowedApps.isEmpty) {
        _showSnackBar('En az bir uygulama seçmelisiniz');
        return;
      }
      
      await _appModel.enterKioskMode();
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _appModel,
      builder: (context, child) {
        if (_appModel.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (_appModel.error != null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Hata',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _appModel.error!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => _appModel.initialize(),
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            ),
          );
        }

        final appsToShow = _showAllApps || _appModel.isKioskMode 
            ? (_appModel.isKioskMode ? _appModel.allowedApps : _appModel.availableApps)
            : _appModel.allowedApps;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Icon(
                  Icons.security,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text('Secure Launcher'),
              ],
            ),
            actions: [
              if (!_appModel.isKioskMode) ...[
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showAllApps = !_showAllApps;
                    });
                  },
                  icon: Icon(_showAllApps ? Icons.check_box : Icons.check_box_outline_blank),
                  tooltip: _showAllApps ? 'Sadece İzinli Uygulamaları Göster' : 'Tüm Uygulamaları Göster',
                ),
                IconButton(
                  onPressed: _showSetPasswordDialog,
                  icon: const Icon(Icons.key),
                  tooltip: 'Şifre Değiştir',
                ),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => SettingsScreen(appModel: _appModel),
                      ),
                    );
                  },
                  icon: const Icon(Icons.settings),
                  tooltip: 'Ayarlar',
                ),
              ],
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: IconButton(
                  onPressed: _handleKioskToggle,
                  icon: Icon(
                    _appModel.isKioskMode ? Icons.lock : Icons.lock_open,
                    color: _appModel.isKioskMode 
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.primary,
                  ),
                  tooltip: _appModel.isKioskMode 
                      ? 'Kiosk Modundan Çık' 
                      : 'Kiosk Moduna Gir',
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              if (!_appModel.isDeviceOwner)
                Container(
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.errorContainer,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Bu uygulama Device Owner değil. Tam kiosk özelliklerini kullanmak için cihazı bu uygulamaya Device Owner olarak atayın.',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_appModel.isKioskMode)
                Container(
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.primaryContainer,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lock,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Kiosk Modu Aktif - Yalnızca izinli uygulamalar kullanılabilir',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: appsToShow.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.apps,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _appModel.isKioskMode
                                  ? 'İzinli uygulama bulunamadı'
                                  : (_showAllApps 
                                      ? 'Uygulama bulunamadı'
                                      : 'Henüz hiç uygulama eklenmedi'),
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            if (!_appModel.isKioskMode && !_showAllApps) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Uygulamaları görmek için yukarıdaki düğmeye basın',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : AppGrid(
                        apps: appsToShow,
                        allowedPackages: _appModel.allowedPackages.toSet(),
                        isKioskMode: _appModel.isKioskMode,
                        onAppTap: _appModel.launchApp,
                        onAppAdd: _appModel.isKioskMode ? null : _appModel.addAllowedApp,
                        onAppRemove: _appModel.isKioskMode ? null : _appModel.removeAllowedApp,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}