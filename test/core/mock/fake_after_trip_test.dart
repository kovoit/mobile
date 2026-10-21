import 'package:flutter_test/flutter_test.dart';
import 'package:kovoit/core/config/demo_account.dart';
import 'package:kovoit/core/mock/fake_trips.dart';
import 'package:kovoit/core/network/api_exception.dart';

import '../../helpers/test_app.dart';

/// Après-trajet et notifications simulés : contrat docs/api/after_trip.md.
void main() {
  late TestEnv env;
  late int bookingId;

  /// Réservation du compte démo sur le trajet de Koffi (07:30), amenée jusqu'à [statut].
  Future<int> bookAndRun(TestEnv env, {String until = 'terminee'}) async {
    final trip = (FakeTrips.search(
      departLat: 6.1660,
      departLng: 1.1650,
      arriveeLat: 6.1680,
      arriveeLng: 1.2140,
      dateHeure: DateTime.utc(2026, 10, 8, 7, 30),
      places: 1,
      typeVehicule: 'voiture',
    )['resultats'] as List).first as Map;
    final id = (await env.bookings.request(tripId: trip['id'] as int, places: 1, pickupPointId: 1, method: 'especes'))['id'] as int;
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
    expect(booking['actions'], containsAll(['confirmer', 'noter', 'signaler']));
  });

  test('confirmation → clôturée, la note reste possible une seule fois', () async {
    final closed = await env.bookings.confirm(bookingId);
    expect(closed['statut'], 'cloturee');
    expect(closed['actions'], isNot(contains('confirmer')));

    await env.afterTrip.rate(bookingId, note: 5, comment: 'Ponctuel et prudent.');
    expect((await env.bookings.get(bookingId))['actions'], isNot(contains('noter')));
    await expectLater(env.afterTrip.rate(bookingId, note: 4), throwsA(isA<ConflictApiException>()));
  });

  test('note hors bornes ou trajet non terminé → refusée', () async {
    await expectLater(env.afterTrip.rate(bookingId, note: 6), throwsA(isA<BadRequestApiException>()));
    final ongoing = TestEnv.demoSession();
    final id = await bookAndRun(ongoing, until: 'en_cours');
    await expectLater(ongoing.afterTrip.rate(id, note: 5), throwsA(isA<ConflictApiException>()));
  });

  test('signalement après le trajet → litige, un seul signalement', () async {
    await env.afterTrip.report(bookingId, reason: 'retard', description: '20 minutes de retard.');
    final booking = await env.bookings.get(bookingId);
    expect(booking['statut'], 'litige');
    expect(booking['actions'], isEmpty);
    await expectLater(
      env.afterTrip.report(bookingId, reason: 'retard', description: 'Encore.'),
      throwsA(isA<ConflictApiException>()),
    );
  });

  test('notifications : une par changement de statut, sans code de départ, marquables comme lues', () async {
    final list = await env.afterTrip.notifications();
    expect(list.map((n) => n['type']), ['trajet_termine', 'prise_en_charge', 'reservation_acceptee']);
    expect(list.every((n) => (n['cible'] as Map)['reservation_id'] == bookingId), isTrue);
    final code = env.backend.bookings[bookingId]!['code_depart'];
    expect(list.toString(), isNot(contains('$code')));

    await env.afterTrip.markRead([list.first['id'] as int]);
    expect((await env.afterTrip.notifications()).where((n) => n['lue'] == false), hasLength(2));
    await env.afterTrip.markRead(null);
    expect((await env.afterTrip.notifications()).every((n) => n['lue'] == true), isTrue);
  });

  test('conducteur : nouvelle demande notifiée, note du passager après le trajet', () async {
    final driver = TestEnv.driverSession();
    final trip = await driver.driver.publish({
      'depart': {'libelle': 'Carrefour Franciscain', 'lat': 6.1660, 'lng': 1.1650},
      'arrivee': {'libelle': 'Université de Lomé', 'lat': 6.1680, 'lng': 1.2140},
      'points_prise_en_charge': [
        {'libelle': 'Carrefour Franciscain', 'lat': 6.1660, 'lng': 1.1650},
      ],
      'depart_le': DateTime.utc(2026, 10, 8, 7, 30).toIso8601String(),
      'places_total': 1,
    });
    expect((await driver.afterTrip.notifications()).first['type'], 'nouvelle_demande');

    final requestId = ((trip['demandes'] as List).first as Map)['id'] as int;
    await driver.driver.accept(requestId);
    await driver.driver.submitCode(requestId, DemoAccount.fakePassengerCode);
    await driver.driver.finishTrip(trip['id'] as int);
    final request = ((await driver.driver.trip(trip['id'] as int))['demandes'] as List).first as Map;
    expect(request['actions'], containsAll(['noter', 'signaler']));

    await driver.afterTrip.rate(requestId, note: 5);
    final after = ((await driver.driver.trip(trip['id'] as int))['demandes'] as List).first as Map;
    expect(after['actions'], ['signaler']);
  });

  test('appareils : enregistrement et oubli du jeton push', () async {
    await env.afterTrip.registerDevice('tok-1');
    expect(env.backend.devices['tok-1'], 1);
    await env.afterTrip.unregisterDevice('tok-1');
    expect(env.backend.devices, isEmpty);
  });
}
