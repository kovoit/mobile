import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum PrimaryButtonVariant { filled, outlined }

/// Bouton pleine largeur des maquettes (« Rechercher un trajet », « Réserver ma place »…).
/// [isLoading] remplace le libellé par un indicateur et désactive le bouton.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.variant = PrimaryButtonVariant.filled,
  });

  const PrimaryButton.outlined({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  }) : variant = PrimaryButtonVariant.outlined;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final PrimaryButtonVariant variant;

  bool get _isFilled => variant == PrimaryButtonVariant.filled;

  @override
  Widget build(BuildContext context) {
    final foreground = _isFilled ? Colors.white : AppColors.textPrimary;
    final child = isLoading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: foreground),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: AppSpacing.xs),
              ],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );

    final effectiveOnPressed = isLoading ? null : onPressed;

    if (!_isFilled) {
      return OutlinedButton(onPressed: effectiveOnPressed, child: child);
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.button),
        boxShadow: effectiveOnPressed == null ? null : AppShadows.button,
      ),
      child: FilledButton(onPressed: effectiveOnPressed, child: child),
    );
  }
}
