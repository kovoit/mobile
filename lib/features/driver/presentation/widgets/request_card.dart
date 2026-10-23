import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../booking/presentation/widgets/booking_labels.dart';
import '../../../trip/domain/entities/trip.dart';
import '../../domain/entities/driver_trip.dart';

/// Demande reçue par le conducteur. Les boutons suivent le statut ; le backend refuse toute
/// action devenue impossible (place prise, absence trop tôt…) avec un message affiché tel quel.
class RequestCard extends StatelessWidget {
  const RequestCard({
    super.key,
    required this.request,
    required this.actions,
    required this.pickup,
    required this.busy,
    required this.onAccept,
    required this.onRefuse,
    required this.onEnterCode,
    required this.onDeclareAbsence,
    required this.onRate,
    required this.onReport,
  });

  final DriverRequest request;
  final Set<DriverRequestAction> actions;
  final PickupPoint? pickup;

  /// Une action est en cours sur cette demande.
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onRefuse;
  final VoidCallback onEnterCode;
  final VoidCallback onDeclareAbsence;
  final VoidCallback onRate;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final passenger = request.passenger;
    final buttons = <Widget>[
      if (actions.contains(DriverRequestAction.accepter))
        PrimaryButton(label: 'Accepter', icon: Icons.check_rounded, isLoading: busy, onPressed: onAccept),
      if (actions.contains(DriverRequestAction.refuser))
        PrimaryButton.outlined(label: 'Refuser', onPressed: busy ? null : onRefuse),
      if (actions.contains(DriverRequestAction.saisirCode))
        PrimaryButton(label: 'Saisir le code', icon: Icons.pin_outlined, isLoading: busy, onPressed: onEnterCode),
      if (actions.contains(DriverRequestAction.declarerAbsence))
        PrimaryButton.outlined(
          label: 'Déclarer absent',
          icon: Icons.person_off_outlined,
          onPressed: busy ? null : onDeclareAbsence,
        ),
      if (actions.contains(DriverRequestAction.noter))
        PrimaryButton.outlined(label: 'Noter', icon: Icons.star_outline_rounded, onPressed: busy ? null : onRate),
      if (actions.contains(DriverRequestAction.signaler))
        PrimaryButton.outlined(
          label: 'Signaler',
          icon: Icons.report_gmailerrorred_rounded,
          onPressed: busy ? null : onReport,
        ),
    ];

    return KovoitCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UserAvatar(name: passenger.nomComplet, photoUrl: passenger.photoUrl, size: 48),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(passenger.nomComplet, style: AppTextStyles.cardTitle),
                    const SizedBox(height: AppSpacing.xxs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xxs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (passenger.verifie) const VerifiedBadge(),
                        request.status.chip,
                      ],
                    ),
                  ],
                ),
              ),
              if (passenger.note != null) RatingLabel(rating: passenger.note!),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 18, color: AppColors.accent),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  '1 place${pickup == null ? '' : ' · ${pickup!.place.libelle}'}',
                  style: AppTextStyles.label,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  request.prix == null || request.commission == 0
                      ? 'Payé par le portefeuille du passager'
                      : 'Vous recevez : ${Formatters.fcfa(request.prix!)} payés − '
                          '${Formatters.fcfa(request.commission)} de commission',
                  style: AppTextStyles.caption,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(Formatters.fcfa(request.montant), style: AppTextStyles.label),
            ],
          ),
          if (buttons.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                for (final (index, button) in buttons.indexed) ...[
                  if (index > 0) const SizedBox(width: AppSpacing.sm),
                  Expanded(child: button),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
