import 'package:flutter/material.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';

/// Saisie par le conducteur du code de départ à 4 chiffres donné par le passager (CA7).
/// Le code est vérifié par le backend ; il n'est ni affiché ailleurs ni conservé.
/// Renvoie `true` si le code est accepté.
class DepartureCodeDialog extends StatefulWidget {
  const DepartureCodeDialog({super.key, required this.passengerName, required this.onSubmit});

  final String passengerName;
  final Future<void> Function(String code) onSubmit;

  static const int codeLength = 4;

  static Future<bool?> show(
    BuildContext context, {
    required String passengerName,
    required Future<void> Function(String code) onSubmit,
  }) =>
      showDialog<bool>(
        context: context,
        builder: (_) => DepartureCodeDialog(passengerName: passengerName, onSubmit: onSubmit),
      );

  @override
  State<DepartureCodeDialog> createState() => _DepartureCodeDialogState();
}

class _DepartureCodeDialogState extends State<DepartureCodeDialog> {
  final _code = TextEditingController();
  bool _checking = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_code.text.length != DepartureCodeDialog.codeLength) {
      setState(() => _error = 'Saisissez les 4 chiffres donnés par le passager.');
      return;
    }
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      await widget.onSubmit(_code.text);
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
      _code.clear();
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Code de départ'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Demandez à ${widget.passengerName} son code à 4 chiffres, une fois à bord.',
            style: AppTextStyles.subtitle,
          ),
          const SizedBox(height: AppSpacing.md),
          OtpCodeInput(
            controller: _code,
            length: DepartureCodeDialog.codeLength,
            autofocus: true,
            hasError: _error != null,
            onChanged: (code) {
              if (_error != null && code.isNotEmpty) setState(() => _error = null);
            },
            onCompleted: (_) => _submit(),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(_error!, textAlign: TextAlign.center, style: AppTextStyles.caption.copyWith(color: AppColors.error)),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: _checking ? null : () => Navigator.pop(context, false), child: const Text('Fermer')),
        FilledButton(
          onPressed: _checking ? null : _submit,
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          child: _checking
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Valider'),
        ),
      ],
    );
  }
}
