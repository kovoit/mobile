import 'package:flutter_test/flutter_test.dart';
import 'package:kovoit/core/mock/fake_trips.dart';
import 'package:kovoit/features/trip/data/dto/trip_dto.dart';
import 'package:kovoit/features/trip/domain/entities/trip.dart';

/// F-057 : tracé de la route renvoyé par le détail d'un trajet (contrat C1), lu tel quel.
void main() {
  const koffiTrip = 'trajet-20261008-00'; // tracé dessiné (`routage`)
  const oldTrip = 'trajet-20261008-06'; // publié avant les tracés : `trace: null`

  Map<String, dynamic> detail(String id) => Map<String, dynamic>.from(FakeTrips.tripById(id)!);

  test('points [lat, lng] et source repris tels quels, du départ à l’arrivée', () {
    final json = detail(koffiTrip)
      ..['trace'] = {
        'source': 'routage',
        'points': [
          [6.17450, 1.16900],
          [6.17501, 1.17003],
          [6.13000, 1.22200],
        ],
      };
    final trace = TripDto.fromJson(json).toEntity().trace!;

    expect(trace.source, TraceSource.routage);
    expect(trace.points, [(lat: 6.1745, lng: 1.169), (lat: 6.17501, lng: 1.17003), (lat: 6.13, lng: 1.222)]);
  });

  test('source `estimation` reconnue', () {
    final json = detail(koffiTrip)
      ..['trace'] = {
        'source': 'estimation',
        'points': [
          [6.166, 1.165],
          [6.168, 1.214],
        ],
      };
    expect(TripDto.fromJson(json).toEntity().trace!.source, TraceSource.estimation);
  });

  test('`trace: null` ou absent (recherche, ancien backend) : pas de tracé', () {
    expect(TripDto.fromJson(detail(oldTrip)).toEntity().trace, isNull);
    expect(TripDto.fromJson(detail(koffiTrip)..remove('trace')).toEntity().trace, isNull);
  });

  test('moins de 2 points : pas de tracé (défense)', () {
    final json = detail(koffiTrip)
      ..['trace'] = {
        'source': 'routage',
        'points': [
          [6.166, 1.165],
        ],
      };
    expect(TripDto.fromJson(json).toEntity().trace, isNull);
  });

  test('le tracé suit le point proposé (withMatch)', () {
    final trip = TripDto.fromJson(detail(koffiTrip)).toEntity();
    final matched = trip.withMatch(pickupId: trip.pickupPoints.last.id);

    expect(matched.trace, same(trip.trace));
    expect(matched.trace!.points.length, greaterThanOrEqualTo(2));
  });

  test('FakeBackend : tracé dans le détail seulement, jamais dans la recherche', () {
    final results = FakeTrips.search(
      departLat: 6.1660,
      departLng: 1.1650,
      arriveeLat: 6.1680,
      arriveeLng: 1.2140,
      dateHeure: DateTime.utc(2026, 10, 8, 7, 30),
    );
    expect(results, isNotEmpty);
    for (final r in results) {
      expect((r['trajet'] as Map).containsKey('trace'), isFalse);
    }

    // Segments droits : exactement [départ, carrefours…, arrivée].
    final estimated = TripDto.fromJson(detail('trajet-20261008-02')).toEntity();
    expect(estimated.trace!.source, TraceSource.estimation);
    expect(estimated.trace!.points, [
      (lat: estimated.depart.lat, lng: estimated.depart.lng),
      for (final p in estimated.pickupPoints) (lat: p.place.lat, lng: p.place.lng),
      (lat: estimated.arrivee.lat, lng: estimated.arrivee.lng),
    ]);
  });
}
