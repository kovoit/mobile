import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

enum StatusTone { success, warning, error, neutral, info }

/// Pastille de statut : « Terminé », « À capturer », « Complétée », « En attente »…
/// Le libellé affiché doit correspondre au statut renvoyé par l'API.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, this.tone = StatusTone.neutral, this.icon});

  final String label;
  final StatusTone tone;
  final IconData? icon;

  (Color foreground, Color background) get _colors => switch (tone) {
        StatusTone.success => (AppColors.success, AppColors.successLight),
        StatusTone.warning => (AppColors.warning, AppColors.warningLight),
        StatusTone.error => (AppColors.error, AppColors.errorLight),
        StatusTone.info => (AppColors.primary, AppColors.border),
        StatusTone.neutral => (AppColors.textSecondary, AppColors.fieldFill),
      };

  @override
  Widget build(BuildContext context) {
    final (foreground, background) = _colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm - 2, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: foreground),
            const SizedBox(width: AppSpacing.xxs + 2),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(color: foreground, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
