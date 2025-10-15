import 'package:flutter/material.dart';
import '../services/app_update_service.dart';

class UpdateAvailableDialog extends StatefulWidget {
  final String appName;
  final AppUpdateInfo updateInfo;
  final VoidCallback onUpdate;
  final VoidCallback? onCancel;

  const UpdateAvailableDialog({
    super.key,
    required this.appName,
    required this.updateInfo,
    required this.onUpdate,
    this.onCancel,
  });

  @override
  State<UpdateAvailableDialog> createState() => _UpdateAvailableDialogState();
}

class _UpdateAvailableDialogState extends State<UpdateAvailableDialog> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  int _receivedBytes = 0;
  int _totalBytes = 0;

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.system_update,
            color: widget.updateInfo.required
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.updateInfo.required ? 'Zorunlu Güncelleme' : 'Güncelleme Mevcut',
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.updateInfo.required)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bu güncelleme zorunludur ve otomatik olarak kurulacaktır.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium,
                children: [
                  const TextSpan(text: ''),
                  TextSpan(
                    text: widget.appName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: ' için yeni bir versiyon mevcut.'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              'Yeni Versiyon',
              widget.updateInfo.version,
              Icons.new_releases,
              Colors.blue,
            ),
            const SizedBox(height: 8),
            _buildInfoCard(
              'Değişiklikler',
              widget.updateInfo.description,
              Icons.description,
              Colors.green,
            ),
            if (_isDownloading) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'İndiriliyor...',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _downloadProgress,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(_downloadProgress * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '${_formatBytes(_receivedBytes)} / ${_formatBytes(_totalBytes)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: _isDownloading
          ? []
          : [
              if (!widget.updateInfo.required)
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onCancel?.call();
                  },
                  child: const Text('Şimdi Değil'),
                ),
              FilledButton.icon(
                onPressed: () {
                  widget.onUpdate();
                },
                icon: const Icon(Icons.download),
                label: const Text('Güncelle'),
              ),
            ],
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  void updateDownloadProgress(int received, int total) {
    if (mounted) {
      setState(() {
        _isDownloading = true;
        _receivedBytes = received;
        _totalBytes = total;
        _downloadProgress = total > 0 ? received / total : 0.0;
      });
    }
  }
}