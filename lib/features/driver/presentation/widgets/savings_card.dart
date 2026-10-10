import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/driver_trip.dart';

/// Bloc sombre « Mes économies ce mois » : le chiffre qui motive le conducteur (spéc.).
/// Montants calculés par le backend.
class SavingsCard extends StatelessWidget {
  const SavingsCard({super.key, required this.savings});

  /// `null` pendant le chargement.
  final DriverSavings? savings;

  @override
  Widget build(BuildContext context) {
    final s = savings;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.card)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Mes économies ce mois :',
                  style: AppTextStyles.label.copyWith(color: Colors.white),
                ),
              ),
              const Icon(Icons.eco_outlined, color: AppColors.accent),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            s == null ? '…' : Formatters.fcfa(s.total),
            style: AppTextStyles.display.copyWith(color: Colors.white, fontSize: 30),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            s == null
                ? 'Chargement…'
                : '${Formatters.monthName(s.month)} · ${s.places} place${s.places > 1 ? 's' : ''} partagée${s.places > 1 ? 's' : ''}',
            style: AppTextStyles.caption.copyWith(color: Colors.white.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}
