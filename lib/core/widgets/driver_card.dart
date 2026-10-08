import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'kovoit_card.dart';
import 'price_tag.dart';
import 'rating_label.dart';
import 'user_avatar.dart';
import 'verified_badge.dart';

/// Carte d'un trajet disponible (écran « Conducteurs disponibles »).
/// Widget de présentation pur : toutes les valeurs (prix, distance, places) viennent de l'API.
class DriverCard extends StatelessWidget {
  const DriverCard({
    super.key,
    required this.driverName,
    required this.vehicleLabel,
    required this.placesLabel,
    required this.departureLabel,
    required this.routeLabel,
    required this.price,
    this.photoUrl,
    this.rating,
    this.isVerified = false,
    this.isMoto = false,
    this.onTap,
  });

  final String driverName;
  final String? photoUrl;
  final double? rating;
  final bool isVerified;
  final bool isMoto;

  /// Ex. « Toyota Yaris ».
  final String vehicleLabel;

  /// Ex. « 2 places restantes ».
  final String placesLabel;

  /// Ex. « Départ 07:30 · 1.2 km de vous ».
  final String departureLabel;

  /// Ex. « Adidogomé → Université de Lomé ».
  final String routeLabel;
  final int price;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return KovoitCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UserAvatar(name: driverName, photoUrl: photoUrl, size: 52),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(driverName, style: AppTextStyles.cardTitle, overflow: TextOverflow.ellipsis),
                    if (isVerified) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      const VerifiedBadge(),
                    ],
                  ],
                ),
              ),
              if (rating != null) RatingLabel(rating: rating!),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                isMoto ? Icons.two_wheeler_rounded : Icons.directions_car_filled_outlined,
                size: 18,
                color: AppColors.accent,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(vehicleLabel, style: AppTextStyles.label),
              const SizedBox(width: AppSpacing.xs),
              Flexible(child: Text(placesLabel, style: AppTextStyles.caption, overflow: TextOverflow.ellipsis)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Divider(),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(departureLabel, style: AppTextStyles.label),
                    const SizedBox(height: 2),
                    Text(routeLabel, style: AppTextStyles.caption, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              PriceTag(amount: price, caption: 'par place →'),
            ],
          ),
        ],
      ),
    );
  }
}
