import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/domain/access_policy.dart';
import '../../domain/entities/kyc_dossier.dart';

/// Texte et action à afficher pour une [AccessDenial].
class AccessDenialMessage {
  const AccessDenialMessage({required this.title, required this.body, this.actionLabel, this.actionRoute});

  final String title;
  final String body;
  final String? actionLabel;
  final String? actionRoute;

  factory AccessDenialMessage.of(AccessDenial denial, {DateTime? suspendedUntil}) => switch (denial) {
        AccessDenial.suspended => AccessDenialMessage(
            title: 'Compte suspendu',
            body: suspendedUntil == null
                ? 'Vous ne pouvez ni réserver ni proposer de trajet pour le moment.'
                : 'Vous ne pouvez ni réserver ni proposer de trajet jusqu’au ${Formatters.date(suspendedUntil)}.',
          ),
        AccessDenial.kycPassagerMissing => AccessDenialMessage(
            title: 'Vérifiez votre identité',
            body: 'Sans cette étape, vous ne pouvez ni réserver ni proposer de trajet.',
            actionLabel: 'Vérifier mon identité',
            actionRoute: Routes.kyc(KycType.passager.apiValue),
          ),
        AccessDenial.kycPassagerPending => const AccessDenialMessage(
            title: 'Vérification en cours',
            body: 'Votre dossier est en cours d’examen. Réservation et mode conducteur seront disponibles dès sa validation.',
          ),
        AccessDenial.kycPassagerRejected => AccessDenialMessage(
            title: 'Dossier d’identité refusé',
            body: 'Consultez le motif et renvoyez vos pièces pour pouvoir réserver.',
            actionLabel: 'Voir le motif',
            actionRoute: Routes.kyc(KycType.passager.apiValue),
          ),
        AccessDenial.kycConducteurMissing => AccessDenialMessage(
            title: 'Dossier conducteur à compléter',
            body: 'Permis, carte grise ou assurance et photo du véhicule sont requis pour publier.',
            actionLabel: 'Compléter mon dossier',
            actionRoute: Routes.kyc(KycType.conducteur.apiValue),
          ),
        AccessDenial.kycConducteurPending => const AccessDenialMessage(
            title: 'Dossier conducteur en cours de vérification',
            body: 'Vous pourrez publier vos trajets dès sa validation.',
          ),
        AccessDenial.kycConducteurRejected => AccessDenialMessage(
            title: 'Dossier conducteur refusé',
            body: 'Consultez le motif et renvoyez vos pièces.',
            actionLabel: 'Voir le motif',
            actionRoute: Routes.kyc(KycType.conducteur.apiValue),
          ),
        AccessDenial.vehicleMissing => const AccessDenialMessage(
            title: 'Déclarez votre véhicule',
            body: 'Marque, modèle, immatriculation et nombre de places sont requis pour publier.',
            actionLabel: 'Déclarer mon véhicule',
            actionRoute: Routes.vehicle,
          ),
      };
}

/// Carte orange affichée sur les tableaux de bord quand réserver / publier est restreint.
class AccessRequiredCard extends StatelessWidget {
  const AccessRequiredCard({super.key, required this.denial, this.suspendedUntil});

  final AccessDenial denial;
  final DateTime? suspendedUntil;

  @override
  Widget build(BuildContext context) {
    final message = AccessDenialMessage.of(denial, suspendedUntil: suspendedUntil);
    final isBlocking = denial == AccessDenial.suspended;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isBlocking ? AppColors.errorLight : AppColors.accentLight,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: (isBlocking ? AppColors.error : AppColors.accent).withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isBlocking ? Icons.block_rounded : Icons.lock_outline_rounded,
                color: isBlocking ? AppColors.error : AppColors.accent,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(message.title, style: AppTextStyles.cardTitle),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(message.body, style: AppTextStyles.subtitle),
                  ],
                ),
              ),
            ],
          ),
          if (message.actionLabel != null) ...[
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: message.actionLabel!,
              icon: Icons.arrow_forward_rounded,
              onPressed: () => context.push(message.actionRoute!),
            ),
          ],
        ],
      ),
    );
  }
}
