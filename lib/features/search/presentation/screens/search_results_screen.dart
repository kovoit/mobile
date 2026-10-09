import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../trip/domain/entities/trip.dart';
import '../../../vehicle/domain/entities/vehicle.dart';
import '../../domain/entities/search_query.dart';
import '../../domain/entities/search_result.dart';
import '../providers/search_providers.dart';

/// Maquette « Conducteurs disponibles ». Les critères viennent de l'URL ; le tri, les distances
/// et les prix viennent de l'API.
class SearchResultsScreen extends ConsumerWidget {
  const SearchResultsScreen({super.key, required this.query});

  final SearchQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(searchResultsProvider(query));
    final subtitle = '${query.depart.displayName} → ${query.arrivee.displayName} · ${Formatters.date(query.dateTime)}';

    return Scaffold(
      appBar: const KovoitAppBar(),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(searchResultsProvider(query).future),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            ScreenHeader(title: 'Conducteurs disponibles', subtitle: subtitle),
            const SizedBox(height: AppSpacing.md),
            ...switch (results) {
              AsyncValue(:final value?) => _results(context, ref, value),
              AsyncValue(:final error?) => [
                  _Message(
                    icon: Icons.wifi_off_rounded,
                    title: 'Recherche impossible',
                    body: error is ApiException ? error.message : 'Une erreur inattendue est survenue.',
                    actionLabel: 'Réessayer',
                    onAction: () => ref.invalidate(searchResultsProvider(query)),
                  ),
                ],
              _ => const [
                  SizedBox(height: AppSpacing.xxl),
                  Center(child: CircularProgressIndicator()),
                ],
            },
          ],
        ),
      ),
    );
  }

  List<Widget> _results(BuildContext context, WidgetRef ref, SearchResult result) {
    final itinerary = result.itinerary;
    final isMoto = query.vehicleType == VehicleType.moto;
    final count = result.trips.length;

    return [
      MapPreview(
        start: LatLng(query.depart.lat, query.depart.lng),
        end: LatLng(query.arrivee.lat, query.arrivee.lng),
        route: [for (final (lat, lng) in itinerary.points) LatLng(lat, lng)],
        startLabel: query.depart.libelle,
        endLabel: query.arrivee.displayName.toUpperCase(),
        badge: '${Formatters.durationMin(itinerary.durationMin)} · ${Formatters.distanceKm(itinerary.distanceKm)}',
        tileProvider: ref.watch(mapTileProviderProvider),
      ),
      const SizedBox(height: AppSpacing.md),
      if (count == 0)
        _Message(
          icon: Icons.search_off_rounded,
          title: 'Aucun trajet ne correspond',
          body: 'Essayez une autre heure, ou un point de départ proche d’un grand carrefour.',
          actionLabel: 'Modifier ma recherche',
          onAction: () => context.pop(),
        )
      else ...[
        Row(
          children: [
            Expanded(
              child: Text(
                '$count trajet${count > 1 ? 's' : ''} en ${isMoto ? 'moto' : 'voiture'}',
                style: AppTextStyles.cardTitle,
              ),
            ),
            StatusChip(
              label: 'Départ dès ${Formatters.time(result.earliestDeparture!)}',
              tone: StatusTone.info,
              icon: Icons.schedule_rounded,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final trip in result.trips) ...[
          _TripCard(trip: trip, onTap: () => context.push(Routes.tripDetail(trip.id, places: query.places))),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    ];
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip, required this.onTap});

  final Trip trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final walking = trip.walkingDistanceKm;
    return DriverCard(
      driverName: trip.driver.nomComplet,
      photoUrl: trip.driver.photoUrl,
      rating: trip.driver.note,
      isVerified: trip.driver.verifie,
      isMoto: trip.vehicle.type == VehicleType.moto,
      vehicleLabel: trip.vehicle.label,
      placesLabel: Formatters.placesRemaining(trip.placesRestantes),
      departureLabel: [
        'Départ ${Formatters.time(trip.departureAt)}',
        if (walking != null) walking < 0.05 ? 'à votre départ' : '${Formatters.distanceKm(walking)} de vous',
      ].join(' · '),
      routeLabel: '${trip.depart.displayName} → ${trip.arrivee.displayName}',
      price: trip.prixPlace,
      onTap: onTap,
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return KovoitCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.textSecondary),
          const SizedBox(height: AppSpacing.sm),
          Text(title, style: AppTextStyles.cardTitle, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xxs),
          Text(body, style: AppTextStyles.subtitle, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton.outlined(label: actionLabel, onPressed: onAction),
        ],
      ),
    );
  }
}
