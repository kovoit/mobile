import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Bloc sombre « À montrer à la prise en charge · Code de départ ».
/// Affiché **uniquement** côté passager (claude.md §1.5). Le code n'est jamais journalisé.
class DepartureCodeCard extends StatelessWidget {
  const DepartureCodeCard({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.card)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: AppColors.accent, size: 20),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'À MONTRER À LA PRISE EN CHARGE',
                  style: AppTextStyles.caption.copyWith(color: Colors.white, letterSpacing: 0.4, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            label: 'Code de départ : ${code.split('').join(' ')}',
            excludeSemantics: true,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Code de départ : ',
                    style: AppTextStyles.body.copyWith(color: Colors.white, fontSize: 17),
                  ),
                  TextSpan(
                    text: code,
                    style: AppTextStyles.display.copyWith(color: Colors.white, fontSize: 36, letterSpacing: 2),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Communiquez ce code uniquement quand vous êtes avec votre conducteur.',
            style: AppTextStyles.subtitle.copyWith(color: Colors.white.withValues(alpha: 0.85)),
          ),
        ],
      ),
    );
  }
}
