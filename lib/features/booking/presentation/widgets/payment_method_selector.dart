import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/booking.dart';
import 'booking_labels.dart';

/// Bloc « Mode de paiement » de la maquette « Détails & Réservation » :
/// Espèces ou Mobile Money, puis Flooz (Moov Africa) ou Mixx (Togocom).
class PaymentMethodSelector extends StatelessWidget {
  const PaymentMethodSelector({super.key, required this.selected, required this.onChanged, this.enabled = true});

  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final mobile = selected.isMobileMoney;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Mode de paiement', style: AppTextStyles.title),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _MethodBox(
                icon: Icons.payments_outlined,
                label: 'Espèces',
                selected: !mobile,
                onTap: enabled ? () => onChanged(PaymentMethod.especes) : null,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _MethodBox(
                icon: Icons.phone_iphone_rounded,
                label: 'Mobile Money',
                selected: mobile,
                onTap: enabled && !mobile ? () => onChanged(PaymentMethod.flooz) : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text('Mobile Money :', style: AppTextStyles.caption),
            for (final method in [PaymentMethod.flooz, PaymentMethod.mixx])
              ChoiceChip(
                label: Text(method.label),
                tooltip: '${method.label} (${method.operator})',
                selected: selected == method,
                onSelected: enabled ? (_) => onChanged(method) : null,
                labelStyle: AppTextStyles.label.copyWith(
                  color: selected == method ? Colors.white : AppColors.textPrimary,
                ),
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.border.withValues(alpha: 0.6),
                showCheckmark: false,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          mobile
              ? 'Paiement ${selected.label} (${selected.operator}) depuis l’application, une fois votre demande acceptée.'
              : 'Paiement au conducteur lors de la prise en charge.',
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
}

class _MethodBox extends StatelessWidget {
  const _MethodBox({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.border.withValues(alpha: 0.45) : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          side: BorderSide(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.6 : 1),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm + 2),
            child: Row(
              children: [
                Icon(icon, size: 22, color: AppColors.textPrimary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(label, style: AppTextStyles.label, maxLines: 1),
                  ),
                ),
                Icon(
                  selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  size: 20,
                  color: selected ? AppColors.primary : AppColors.textDisabled,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
