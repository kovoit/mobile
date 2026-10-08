import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'kovoit_card.dart';

/// Carte « Avancement » du parcours KYC : barre de progression + libellés d'étapes.
class StepProgress extends StatelessWidget {
  const StepProgress({
    super.key,
    required this.completed,
    required this.total,
    this.title = 'Avancement',
    this.stepLabels = const [],
  }) : assert(total > 0 && completed >= 0 && completed <= total);

  final int completed;
  final int total;
  final String title;
  final List<String> stepLabels;

  @override
  Widget build(BuildContext context) {
    return KovoitCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: AppTextStyles.label)),
              Text(
                '$completed/$total terminés',
                style: AppTextStyles.label.copyWith(color: AppColors.success),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: completed / total,
              minHeight: 8,
              color: AppColors.success,
              backgroundColor: AppColors.border,
            ),
          ),
          if (stepLabels.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [for (final label in stepLabels) Text(label, style: AppTextStyles.caption)],
            ),
          ],
        ],
      ),
    );
  }
}
