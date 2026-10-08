import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Sélecteur « − n + » (nombre de places). Les bornes viennent de l'appelant
/// (ex. places du véhicule − 1, fournies par l'API).
class PlaceStepper extends StatelessWidget {
  const PlaceStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 4,
  }) : assert(min <= max);

  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepButton(
          icon: Icons.remove_rounded,
          tooltip: 'Retirer une place',
          filled: false,
          onPressed: value > min ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 40,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: AppTextStyles.cardTitle,
            semanticsLabel: '$value place${value > 1 ? 's' : ''}',
          ),
        ),
        _StepButton(
          icon: Icons.add_rounded,
          tooltip: 'Ajouter une place',
          filled: true,
          onPressed: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.tooltip, required this.filled, this.onPressed});

  final IconData icon;
  final String tooltip;
  final bool filled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final background = filled && enabled ? AppColors.primary : AppColors.fieldFill;
    final foreground = filled && enabled
        ? Colors.white
        : enabled
            ? AppColors.textPrimary
            : AppColors.textDisabled;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: SizedBox(
            width: AppSpacing.xxl,
            height: AppSpacing.xxl,
            child: Icon(icon, size: 20, color: foreground),
          ),
        ),
      ),
    );
  }
}
