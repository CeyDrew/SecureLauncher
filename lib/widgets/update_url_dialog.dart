import 'package:flutter/material.dart';
import '../services/app_update_service.dart';

class UpdateUrlDialog extends StatefulWidget {
  final String packageName;
  final String appName;
  final String? currentUrl;

  const UpdateUrlDialog({
    super.key,
    required this.packageName,
    required this.appName,
    this.currentUrl,
  });

  @override
  State<UpdateUrlDialog> createState() => _UpdateUrlDialogState();
}

class _UpdateUrlDialogState extends State<UpdateUrlDialog> {
  late final TextEditingController _urlController;
  final AppUpdateService _updateService = AppUpdateService();
  bool _isValidating = false;
  String? _errorMessage;
  AppUpdateInfo? _validatedInfo;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.currentUrl ?? '');
  }

  @override
  void dispose() {
    _urlController.dispose();
    _updateService.dispose();
    super.dispose();
  }

  Future<void> _validateUrl() async {
    setState(() {
      _isValidating = true;
      _errorMessage = null;
      _validatedInfo = null;
    });

    try {
      final url = _urlController.text.trim();
      if (url.isEmpty) {
        throw Exception('URL boş olamaz');
      }

      final updateInfo = await _updateService.validateUpdateUrl(url);
      setState(() {
        _validatedInfo = updateInfo;
        _isValidating = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isValidating = false;
      });
    }
  }

  void _save() {
    final url = _urlController.text.trim();
    if (url.isNotEmpty) {
      Navigator.of(context).pop(url);
    }
  }

  void _remove() {
    Navigator.of(context).pop(''); // Boş string = URL'i kaldır
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.appName} - Güncelleme URL\'i'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Bu uygulamanın güncelleme kontrolü için kullanılacak JSON dosyasının URL\'ini girin:',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'Güncelleme URL\'i',
                hintText: 'https://example.com/update.json',
                border: const OutlineInputBorder(),
                errorText: _errorMessage,
              ),
              keyboardType: TextInputType.url,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isValidating ? null : _validateUrl,
                    icon: _isValidating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(_isValidating ? 'Doğrulanıyor...' : 'URL\'yi Doğrula'),
                  ),
                ),
              ],
            ),
            if (_validatedInfo != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'JSON Doğrulandı',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const Divider(),
                    _buildInfoRow('Versiyon', _validatedInfo!.version),
                    _buildInfoRow('Zorunlu', _validatedInfo!.required ? 'Evet' : 'Hayır'),
                    _buildInfoRow('Açıklama', _validatedInfo!.description),
                    _buildInfoRow('APK URL', _validatedInfo!.url, maxLines: 2),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (widget.currentUrl != null)
          TextButton.icon(
            onPressed: _remove,
            icon: const Icon(Icons.delete_outline),
            label: const Text('URL\'yi Kaldır'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        FilledButton.icon(
          onPressed: _validatedInfo != null ? _save : null,
          icon: const Icon(Icons.save),
          label: const Text('Kaydet'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}