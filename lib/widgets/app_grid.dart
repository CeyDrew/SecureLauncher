import 'package:flutter/material.dart';
import '../services/kiosk_platform_service.dart';

class AppGrid extends StatelessWidget {
  final List<LaunchableApp> apps;
  final Function(String) onAppTap;
  final Function(String)? onAppAdd;
  final Function(String)? onAppRemove;
  final Set<String> allowedPackages;
  final bool isKioskMode;

  const AppGrid({
    super.key,
    required this.apps,
    required this.onAppTap,
    this.onAppAdd,
    this.onAppRemove,
    required this.allowedPackages,
    required this.isKioskMode,
  });

  @override
  Widget build(BuildContext context) {
    if (apps.isEmpty) {
      return const Center(
        child: Text('Uygulama bulunamadı'),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: apps.length,
      itemBuilder: (context, index) {
        final app = apps[index];
        final isAllowed = allowedPackages.contains(app.packageName);

        return AppTile(
          app: app,
          isAllowed: isAllowed,
          isKioskMode: isKioskMode,
          onTap: () => onAppTap(app.packageName),
          onAdd: onAppAdd != null ? () => onAppAdd!(app.packageName) : null,
          onRemove: onAppRemove != null ? () => onAppRemove!(app.packageName) : null,
        );
      },
    );
  }
}

class AppTile extends StatelessWidget {
  final LaunchableApp app;
  final bool isAllowed;
  final bool isKioskMode;
  final VoidCallback onTap;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;

  const AppTile({
    super.key,
    required this.app,
    required this.isAllowed,
    required this.isKioskMode,
    required this.onTap,
    this.onAdd,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: isKioskMode || isAllowed ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: isKioskMode || isAllowed 
                          ? null 
                          : Colors.grey.withOpacity(0.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        app.iconBytes,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        color: isKioskMode || isAllowed 
                            ? null 
                            : Colors.grey,
                        colorBlendMode: isKioskMode || isAllowed 
                            ? null 
                            : BlendMode.saturation,
                      ),
                    ),
                  ),
                  if (!isKioskMode && !isAllowed && onAdd != null)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          iconSize: 12,
                          onPressed: onAdd,
                          icon: const Icon(
                            Icons.add,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  if (!isKioskMode && isAllowed && onRemove != null)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          iconSize: 12,
                          onPressed: onRemove,
                          icon: const Icon(
                            Icons.remove,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                app.appName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isKioskMode || isAllowed 
                      ? null 
                      : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}