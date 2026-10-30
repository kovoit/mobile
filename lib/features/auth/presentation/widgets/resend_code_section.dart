import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// « Renvoyer le code » après le délai (`delai_renvoi_s`), avec compte à rebours.
class ResendCodeSection extends StatelessWidget {
  const ResendCodeSection({
    super.key,
    required this.remaining,
    required this.isSending,
    required this.error,
    required this.onResend,
  });

  final Duration remaining;
  final bool isSending;
  final String? error;
  final VoidCallback onResend;

  String get _countdown {
    final minutes = remaining.inMinutes.toString().padLeft(2, '0');
    final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Vous n’avez pas reçu l’e-mail ? Pensez aux spams.',
          textAlign: TextAlign.center,
          style: AppTextStyles.subtitle,
        ),
        const SizedBox(height: AppSpacing.xxs),
        if (isSending)
          const Text('Envoi du code…', style: AppTextStyles.subtitle)
        else if (remaining > Duration.zero)
          Text('Renvoyer le code dans $_countdown', style: AppTextStyles.subtitle)
        else
          TextButton(onPressed: onResend, child: const Text('Renvoyer le code')),
        if (error != null)
          Text(error!, textAlign: TextAlign.center, style: AppTextStyles.caption.copyWith(color: AppColors.error)),
      ],
    );
  }
}
