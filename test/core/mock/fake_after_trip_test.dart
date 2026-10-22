import 'package:flutter_test/flutter_test.dart';
import 'package:kovoit/core/config/demo_account.dart';
import 'package:kovoit/core/mock/fake_trips.dart';
import 'package:kovoit/core/network/api_exception.dart';
import 'package:kovoit/features/booking/domain/entities/booking.dart';

import '../../helpers/test_app.dart';

/// Après-trajet simulé (notes, signalements, appareils), même contrat que le backend.
void main() {
  late TestEnv env;
  late String bookingId;

  /// Réservation du compte démo sur le trajet de Koffi (07:30), amenée jusqu'à [until].
  Future<String> bookAndRun(TestEnv env, {String until = 'terminee'}) async {
    final first = FakeTrips.search(
      departLat: 6.1660,
      departLng: 1.1650,
      arriveeLat: 6.1680,
      arriveeLng: 1.2140,
      dateHeure: DateTime.utc(2026, 10, 8, 7, 30),
    ).first;
    final booking = await env.bookings.request(
      tripId: (first['trajet'] as Map)['id'] as String,
      pickupPointId: (first['point_propose'] as Map)['id'] as String,
      arriveeLat: 6.168,
      arriveeLng: 1.214,
    );
    final id = booking['id'] as String;
    await env.bookings.simulateDriverAccepts(id);
    if (until == 'acceptee') return id;
    await env.bookings.simulatePickup(id);
    if (until == 'en_cours') return id;
    await env.bookings.simulateTripFinished(id);
    return id;
  }

  setUp(() async {
    env = TestEnv.demoSession();
    bookingId = await bookAndRun(env);
  });

  test('trajet terminé : confirmer, noter et signaler sont proposés', () async {
    final booking = await env.bookings.get(bookingId);
    expect(booking['statut'], 'terminee');
    expect(
      BookingAction.forStatus(BookingStatus.terminee),
      containsAll([BookingAction.confirmer, BookingAction.noter, BookingAction.signaler]),
    );
  });

  test('confirmation → clôturée, la note est acceptée une seule fois', () async {
    final closed = await env.bookings.confirm(bookingId);
    expect(closed['statut'], 'cloturee');

    await env.afterTrip.rate(bookingId, note: 5, comment: 'Ponctuel et prudent.');
    await expectLater(
      env.afterTrip.rate(bookingId, note: 4),
      throwsA(isA<ConflictApiException>().having((e) => e.code, 'code', 'DEJA_NOTE')),
    );
  });

  test('note hors bornes ou trajet non terminé → refusée', () async {
    await expectLater(env.afterTrip.rate(bookingId, note: 6), throwsA(isA<BadRequestApiException>()));
    final ongoing = TestEnv.demoSession();
    final id = await bookAndRun(ongoing, until: 'en_cours');
    await expectLater(
      ongoing.afterTrip.rate(id, note: 5),
      throwsA(isA<ConflictApiException>().having((e) => e.code, 'code', 'NOTE_PREMATUREE')),
    );
  });

  test('signalement après le trajet → litige', () async {
    await env.afterTrip.report(bookingId, motif: 'Retard important — 20 minutes de retard.');
    final booking = await env.bookings.get(bookingId);
    expect(booking['statut'], 'litige');
    expect(env.backend.reports.values.single, startsWith('Retard important'));
  });

  test('signalement avant la prise en charge → refusé', () async {
    final early = TestEnv.demoSession();
    final id = await bookAndRun(early, until: 'acceptee');
    await expectLater(
      early.afterTrip.report(id, motif: 'Autre — test'),
      throwsA(isA<ConflictApiException>().having((e) => e.code, 'code', 'SIGNALEMENT_IMPOSSIBLE')),
    );
  });

  test('conducteur : note du passager après le trajet', () async {
    final driver = TestEnv.driverSession();
    final trip = await driver.driver.publish({
      'vehicule_id': 'v-2',
      'depart_lat': 6.1660,
      'depart_lng': 1.1650,
      'depart_libelle': 'Carrefour Franciscain',
      'arrivee_lat': 6.1680,
      'arrivee_lng': 1.2140,
      'arrivee_libelle': 'Université de Lomé',
      'depart_le': DateTime.utc(2026, 10, 8, 7, 30).toIso8601String(),
      'places': 1,
      'points': [
        {'lat': 6.1660, 'lng': 1.1650, 'libelle': 'Carrefour Franciscain'},
      ],
    });
    final requestId = (await driver.driver.requests(trip['id'] as String)).first['id'] as String;
    await driver.driver.accept(requestId);
    await driver.driver.submitCode(requestId, DemoAccount.fakePassengerCode);
    await driver.driver.finishTrip(trip['id'] as String);

    await driver.afterTrip.rate(requestId, note: 5);
    await expectLater(driver.afterTrip.rate(requestId, note: 5), throwsA(isA<ConflictApiException>()));
  });

  test('appareils : enregistrement et oubli du jeton push', () async {
    await env.afterTrip.registerDevice('tok-1');
    expect(env.backend.devices['tok-1'], 1);
    await env.afterTrip.unregisterDevice('tok-1');
    expect(env.backend.devices, isEmpty);
  });
}
