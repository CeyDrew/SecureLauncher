import 'package:flutter/material.dart';

class PasswordDialog extends StatefulWidget {
  final String title;
  final String? hintText;
  final bool isConfirmation;

  const PasswordDialog({
    super.key,
    required this.title,
    this.hintText,
    this.isConfirmation = false,
  });

  @override
  State<PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<PasswordDialog> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.hintText != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                widget.hintText!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Şifre',
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
          ),
          if (widget.isConfirmation) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _confirmController,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: 'Şifre Tekrarı',
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _obscureConfirm = !_obscureConfirm;
                    });
                  },
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: () {
            final password = _passwordController.text;
            if (password.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Şifre boş olamaz')),
              );
              return;
            }

            if (widget.isConfirmation) {
              final confirm = _confirmController.text;
              if (password != confirm) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Şifreler eşleşmiyor')),
                );
                return;
              }
            }

            Navigator.of(context).pop(password);
          },
          child: const Text('Tamam'),
        ),
      ],
    );
  }
}