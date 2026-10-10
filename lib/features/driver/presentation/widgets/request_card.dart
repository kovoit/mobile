import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../booking/presentation/widgets/booking_labels.dart';
import '../../../trip/domain/entities/trip.dart';
import '../../domain/entities/driver_trip.dart';

/// Demande reçue par le conducteur. Les boutons affichés sont exactement les `actions` de l'API.
class RequestCard extends StatelessWidget {
  const RequestCard({
    super.key,
    required this.request,
    required this.pickup,
    required this.busy,
    required this.onAccept,
    required this.onRefuse,
    required this.onEnterCode,
    required this.onDeclareAbsence,
  });

  final DriverRequest request;
  final PickupPoint? pickup;

  /// Une action est en cours sur cette demande.
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onRefuse;
  final VoidCallback onEnterCode;
  final VoidCallback onDeclareAbsence;

  @override
  Widget build(BuildContext context) {
    final passenger = request.passenger;
    final buttons = <Widget>[
      if (request.can(DriverRequestAction.accepter))
        PrimaryButton(label: 'Accepter', icon: Icons.check_rounded, isLoading: busy, onPressed: onAccept),
      if (request.can(DriverRequestAction.refuser))
        PrimaryButton.outlined(label: 'Refuser', onPressed: busy ? null : onRefuse),
      if (request.can(DriverRequestAction.saisirCode))
        PrimaryButton(label: 'Saisir le code', icon: Icons.pin_outlined, isLoading: busy, onPressed: onEnterCode),
      if (request.can(DriverRequestAction.declarerAbsence))
        PrimaryButton.outlined(
          label: 'Déclarer absent',
          icon: Icons.person_off_outlined,
          onPressed: busy ? null : onDeclareAbsence,
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
                  '${request.places} place${request.places > 1 ? 's' : ''}'
                  '${pickup == null ? '' : ' · ${pickup!.place.libelle}'}',
                  style: AppTextStyles.label,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Row(
            children: [
              Icon(request.paymentMethod.icon, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  '${request.paymentMethod.label} · ${request.paymentStatus.label}',
                  style: AppTextStyles.caption,
                ),
              ),
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
