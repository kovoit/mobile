import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/widgets/map_preview.dart';
import '../../domain/entities/trip.dart';

/// Carte du détail d'un trajet : la route du conducteur telle que renvoyée par l'API (`trace`),
/// du départ à l'arrivée par les carrefours, le carrefour proposé au passager mis en avant et son
/// point d'arrêt s'il est connu. Aucun calcul d'itinéraire ni de distance dans l'app.
/// Sans tracé (trajet ancien), rien n'est affiché.
class TripRouteMap extends ConsumerWidget {
  const TripRouteMap({super.key, required this.trip, this.passengerStop});

  final Trip trip;

  /// Point d'arrêt du passager (`alat` / `alng` de l'URL), s'il a été choisi.
  final ({double lat, double lng})? passengerStop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trace = trip.trace;
    if (trace == null) return const SizedBox.shrink();
    final proposedId = trip.matchedPickup?.id;
    final stop = passengerStop;
    return MapPreview(
      start: LatLng(trip.depart.lat, trip.depart.lng),
      end: LatLng(trip.arrivee.lat, trip.arrivee.lng),
      route: [for (final p in trace.points) LatLng(p.lat, p.lng)],
      // Le carrefour proposé est dessiné après les autres pour rester visible s'ils se chevauchent.
      waypoints: [
        for (final p in trip.pickupPoints)
          if (p.id != proposedId) MapWaypoint(LatLng(p.place.lat, p.place.lng)),
        for (final p in trip.pickupPoints)
          if (p.id == proposedId) MapWaypoint(LatLng(p.place.lat, p.place.lng), kind: MapWaypointKind.proposedPickup),
        if (stop != null) MapWaypoint(LatLng(stop.lat, stop.lng), kind: MapWaypointKind.passengerStop),
      ],
      tileProvider: ref.watch(mapTileProviderProvider),
    );
  }
}
