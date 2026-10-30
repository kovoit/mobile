import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kovoit/core/mock/fake_trips.dart';
import 'package:kovoit/core/router/routes.dart';
import 'package:kovoit/core/widgets/map_preview.dart';
import 'package:kovoit/features/trip/data/dto/trip_dto.dart';
import 'package:kovoit/features/trip/domain/entities/trip.dart';
import 'package:kovoit/features/trip/presentation/widgets/trip_route_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../helpers/flows.dart';
import '../../../helpers/test_app.dart';

/// F-057 : la carte du détail d'un trajet dessine la route renvoyée par l'API.
void main() {
  setUpAll(() => initializeDateFormatting('fr'));

  Trip detail(String id) => TripDto.fromJson(FakeTrips.tripById(id)!).toEntity();

  Future<void> pumpMap(WidgetTester tester, Trip trip, {({double lat, double lng})? stop}) => tester.pumpWidget(
        ProviderScope(
          overrides: [mapTileProviderProvider.overrideWithValue(TransparentTileProvider())],
          child: MaterialApp(home: Scaffold(body: TripRouteMap(trip: trip, passengerStop: stop))),
        ),
      );

  List<LatLng> polyline(WidgetTester tester) =>
      tester.widget<PolylineLayer>(find.byType(PolylineLayer)).polylines.single.points;

  List<Marker> markers(WidgetTester tester) => tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers;

  testWidgets('CA-057-1 : la polyligne reprend tous les points du tracé ; départ, carrefours, '
      'point proposé, point d’arrêt et arrivée marqués', (tester) async {
    final base = detail('trajet-20261008-00');
    final proposed = base.pickupPoints[1];
    final trip = base.withMatch(pickupId: proposed.id);
    const stop = (lat: 6.1702, lng: 1.2110);
    await pumpMap(tester, trip, stop: stop);
    await tester.pumpAndSettle();

    expect(polyline(tester), [for (final p in trip.trace!.points) LatLng(p.lat, p.lng)]);

    final points = [for (final m in markers(tester)) m.point];
    expect(points, contains(LatLng(trip.depart.lat, trip.depart.lng)));
    expect(points, contains(LatLng(trip.arrivee.lat, trip.arrivee.lng)));
    for (final p in trip.pickupPoints) {
      expect(points, contains(LatLng(p.place.lat, p.place.lng)), reason: p.place.libelle);
    }
    expect(points, contains(LatLng(stop.lat, stop.lng)));
    expect(points, hasLength(2 + trip.pickupPoints.length + 1));

    // Le carrefour proposé au passager est mis en avant, une seule fois.
    expect(find.byIcon(Icons.hail_rounded), findsOneWidget);
    final highlighted = markers(tester).singleWhere(
      (m) => find.descendant(of: find.byWidget(m.child), matching: find.byIcon(Icons.hail_rounded)).evaluate().isNotEmpty,
    );
    expect(highlighted.point, LatLng(proposed.place.lat, proposed.place.lng));
    expect(find.byIcon(Icons.flag_rounded), findsOneWidget);
    expect(find.textContaining('estimé'), findsNothing);
  });

  testWidgets('sans point d’arrêt : pas de marqueur de descente', (tester) async {
    await pumpMap(tester, detail('trajet-20261008-02'));
    await tester.pumpAndSettle();

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byIcon(Icons.flag_rounded), findsNothing);
  });

  testWidgets('`trace: null` : aucune carte', (tester) async {
    final trip = detail('trajet-20261008-06');
    expect(trip.trace, isNull);
    await pumpMap(tester, trip);
    await tester.pumpAndSettle();

    expect(find.byType(FlutterMap), findsNothing);
  });

  testWidgets('écran Détails & Réservation : carte du tracé au-dessus de l’itinéraire', (tester) async {
    await pumpKovoitApp(tester, env: TestEnv.demoSession());
    await openKoffiTrip(tester);

    expect(find.byType(TripRouteMap), findsOneWidget);
    expect(polyline(tester), hasLength(detail('trajet-20261008-00').trace!.points.length));
    expect(
      tester.getTopLeft(find.byType(TripRouteMap)).dy,
      lessThan(tester.getTopLeft(find.textContaining('PRISE EN CHARGE')).dy),
    );
    // Point d'arrêt du passager (destination de la recherche, dans l'URL) marqué.
    expect(find.byIcon(Icons.flag_rounded), findsOneWidget);
  });

  testWidgets('écran Détails & Réservation d’un ancien trajet (`trace: null`) : écran sans carte', (tester) async {
    await pumpKovoitApp(tester, env: TestEnv.demoSession());
    unawaited(GoRouter.of(tester.element(find.byType(Scaffold).first)).push<void>(Routes.tripDetail('trajet-20261008-06')));
    await tester.pumpAndSettle();

    expect(find.text('Détails & Réservation'), findsOneWidget);
    expect(find.byType(TripRouteMap), findsNothing);
    expect(find.byType(FlutterMap), findsNothing);
    expect(find.textContaining('PRISE EN CHARGE'), findsOneWidget);
  });
}
