import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../domain/entities/kyc_dossier.dart';
import '../providers/kyc_providers.dart';
import '../widgets/kyc_labels.dart';

/// Maquette « Profil vérifié ». Le KYC étant validé à la main par l'administrateur,
/// l'écran affiche « Dossier envoyé » tant que le statut est en attente, « Profil vérifié » une fois validé.
class KycSubmittedScreen extends ConsumerWidget {
  const KycSubmittedScreen({super.key, required this.type});

  final KycType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dossier = ref.watch(kycControllerProvider).value?[type];
    final verified = dossier?.status == KycStatus.verifie;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            const SizedBox(height: AppSpacing.xl),
            KovoitCard(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: verified ? AppColors.success : AppColors.accent,
                      boxShadow: [
                        BoxShadow(
                          color: (verified ? AppColors.success : AppColors.accent).withValues(alpha: 0.2),
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: Icon(verified ? Icons.check_rounded : Icons.hourglass_top_rounded, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ScreenHeader(
                    title: verified ? 'Profil vérifié' : 'Dossier envoyé',
                    subtitle: verified
                        ? 'Merci d’avoir vérifié votre identité.'
                        : 'Merci ! Un administrateur vérifie vos pièces. Vous serez notifié de sa décision.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (dossier != null)
              KovoitCard(
                child: Column(
                  children: [
                    for (final (index, piece) in dossier.pieces.indexed) ...[
                      if (index > 0) const Divider(height: AppSpacing.lg),
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.fieldFill,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Icon(piece.type.icon, color: AppColors.textPrimary),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(piece.type.title, style: AppTextStyles.label),
                                const SizedBox(height: AppSpacing.xxs),
                                const StatusChip(label: 'Complétée', tone: StatusTone.success, icon: Icons.check_rounded),
                              ],
                            ),
                          ),
                          const Icon(Icons.check_circle_rounded, color: AppColors.success),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(label: 'Continuer', onPressed: () => context.go(Routes.profile)),
          ],
        ),
      ),
    );
  }
}
