import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Bouton « Continuer avec Google » des maquettes Connexion / Inscription.
class GoogleButton extends StatelessWidget {
  const GoogleButton({super.key, required this.onPressed, this.isLoading = false});

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
          : const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _GoogleMark(),
                SizedBox(width: AppSpacing.sm),
                Flexible(child: Text('Continuer avec Google', overflow: TextOverflow.ellipsis)),
              ],
            ),
    );
  }
}

/// Pastille « G » provisoire. À remplacer par le logo Google officiel (asset) avant publication.
class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm - 2),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        'G',
        style: AppTextStyles.cardTitle.copyWith(color: AppColors.googleBlue, fontWeight: FontWeight.w800),
      ),
    );
  }
}
