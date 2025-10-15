import 'package:flutter/material.dart';

class DownloadProgressDialog extends StatefulWidget {
  final String appName;
  final String version;

  const DownloadProgressDialog({
    super.key,
    required this.appName,
    required this.version,
  });

  @override
  State<DownloadProgressDialog> createState() => DownloadProgressDialogState();
}

class DownloadProgressDialogState extends State<DownloadProgressDialog>
    with SingleTickerProviderStateMixin {
  double _progress = 0.0;
  int _receivedBytes = 0;
  int _totalBytes = 0;
  bool _isInstalling = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void updateProgress(int received, int total) {
    if (mounted) {
      setState(() {
        _receivedBytes = received;
        _totalBytes = total;
        if (total > 0) {
          _progress = received / total;
        }
      });
    }
  }

  void setInstalling(bool installing) {
    if (mounted) {
      setState(() {
        _isInstalling = installing;
      });
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = (_progress * 100).toStringAsFixed(0);

    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 8,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.surface,
                  theme.colorScheme.surface.withOpacity(0.95),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon ve Başlık
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isInstalling ? Icons.install_mobile : Icons.download,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 20),

                // Uygulama Adı
                Text(
                  widget.appName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Versiyon
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'v${widget.version}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Progress Indicator ve Yüzde
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Circular Progress
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: _isInstalling ? null : _progress,
                        strokeWidth: 8,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    // Yüzde Metni
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!_isInstalling) ...[
                          Text(
                            '$percentage%',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          if (_totalBytes > 0)
                            Text(
                              '${_formatBytes(_receivedBytes)} / ${_formatBytes(_totalBytes)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ] else
                          Column(
                            children: [
                              Icon(
                                Icons.install_mobile,
                                size: 32,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Kuruluyor',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Linear Progress Bar
                if (!_isInstalling) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 8,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Durum Metni
                Text(
                  _isInstalling
                      ? 'Güncelleme kuruluyor, lütfen bekleyin...'
                      : _progress < 0.01
                          ? 'İndirme başlatılıyor...'
                          : 'İndiriliyor...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),

                if (_isInstalling) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Kurulum tamamlandığında uygulama otomatik olarak güncellenecek',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}