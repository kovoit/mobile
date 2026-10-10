import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/driver_trip.dart';
import 'driver_trip_labels.dart';

/// Ligne résumant un trajet publié (Espace Conducteur, Mes trajets).
class DriverTripTile extends StatelessWidget {
  const DriverTripTile({super.key, required this.trip, required this.onTap});

  final DriverTrip trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pending = trip.pendingRequests;
    return KovoitCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${Formatters.shortDate(trip.departureAt)} · ${Formatters.time(trip.departureAt)}',
                  style: AppTextStyles.label,
                ),
              ),
              trip.status.chip,
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            '${trip.depart.displayName} → ${trip.arrivee.displayName}',
            style: AppTextStyles.cardTitle,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${trip.placesRestantes}/${trip.placesTotal} places libres · ${Formatters.fcfa(trip.prixPlace)} / place',
                  style: AppTextStyles.caption,
                ),
              ),
              if (pending > 0)
                Badge(
                  label: Text('$pending'),
                  backgroundColor: AppColors.accent,
                  child: const Padding(
                    padding: EdgeInsets.only(right: AppSpacing.xs),
                    child: Text('Demandes', style: AppTextStyles.caption),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
