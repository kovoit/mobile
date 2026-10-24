import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/external_actions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// « J'accepte les conditions d'utilisation » + lien pour les lire (navigateur).
class TermsCheckbox extends ConsumerWidget {
  const TermsCheckbox({super.key, required this.value, required this.onChanged, required this.url, this.error});

  final bool value;
  final ValueChanged<bool> onChanged;
  final String url;
  final String? error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          value: value,
          onChanged: (v) => onChanged(v ?? false),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('J’accepte les conditions d’utilisation de Kovoit', style: AppTextStyles.body),
        ),
        TextButton(
          onPressed: () => ref.read(externalActionsProvider).openUrl(url),
          child: const Text('Lire les conditions d’utilisation'),
        ),
        if (error != null) Text(error!, style: AppTextStyles.caption.copyWith(color: AppColors.error)),
      ],
    );
  }
}
