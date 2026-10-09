import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Champ « sélecteur » des maquettes (lieu, date, heure) : même apparence qu'un champ de saisie,
/// mais ouvre un écran ou une boîte de dialogue au toucher.
class PickerField extends StatelessWidget {
  const PickerField({
    super.key,
    required this.icon,
    required this.hint,
    required this.onTap,
    this.label,
    this.value,
    this.iconColor,
    this.errorText,
  });

  final String? label;
  final IconData icon;
  final Color? iconColor;
  final String hint;

  /// Valeur affichée ; `null` → [hint] en gris.
  final String? value;
  final VoidCallback onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.xs),
        ],
        Semantics(
          button: true,
          label: label,
          value: value ?? hint,
          child: Material(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.field),
              side: BorderSide(color: hasError ? AppColors.error : AppColors.border),
            ),
            child: InkWell(
              onTap: onTap,
              customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 15),
                child: Row(
                  children: [
                    Icon(icon, size: 21, color: iconColor ?? AppColors.textSecondary),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        value ?? hint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(color: value == null ? AppColors.textDisabled : null),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(errorText!, style: AppTextStyles.caption.copyWith(color: AppColors.error)),
        ],
      ],
    );
  }
}
