import 'package:flutter_test/flutter_test.dart';
import 'package:kovoit/core/config/demo_account.dart';
import 'package:kovoit/core/mock/fake_driver.dart';
import 'package:kovoit/core/network/api_exception.dart';

import '../../helpers/test_app.dart';

/// Le conducteur simulé doit respecter docs/api/driver.md : la démo et les tests de widgets en dépendent.
void main() {
  late TestEnv env;
  late FakeDriver driver;

  const franciscain = {'libelle': 'Carrefour Franciscain', 'quartier': 'Adidogomé', 'lat': 6.1660, 'lng': 1.1650};
  const universite = {'libelle': 'Université de Lomé · Entrée sud', 'quartier': 'Tokoin', 'lat': 6.1680, 'lng': 1.2140};

  setUp(() {
    env = TestEnv.driverSession(); // 07:20 le 08/10/2026
    driver = env.driver;
  });

  Map<String, dynamic> body({int places = 1, List<Map<String, dynamic>>? pickups, DateTime? when}) => {
        'depart': franciscain,
        'arrivee': universite,
        'points_prise_en_charge': pickups ?? [franciscain],
        'depart_le': (when ?? DateTime.utc(2026, 10, 8, 7, 30)).toIso8601String(),
        'places_total': places,
      };

  List<Map<String, dynamic>> requests(Map<String, dynamic> trip) => (trip['demandes'] as List).cast();

  test('prix recommandé selon la grille (décision D1 en attente)', () async {
    final estimate = await driver.estimate(depart: franciscain, arrivee: universite);
    expect(estimate['prix_place'], 300);
    expect(FakeDriver.priceFor(3), 200);
    expect(FakeDriver.priceFor(12), 500);
  });

  test('publication : erreurs par champ', () async {
    await expectLater(
      driver.publish(body(places: 5, pickups: [], when: DateTime.utc(2026, 10, 8, 7))),
      throwsA(
        isA<BadRequestApiException>().having(
          (e) => e.fieldErrors.keys,
          'champs',
          containsAll(['points_prise_en_charge', 'places_total', 'depart_le']),
        ),
      ),
    );
  });

  test('publication : trajet publié, demandes fictives, aucun code de départ exposé', () async {
    final trip = await driver.publish(body());
    expect(trip['statut'], 'publie');
    expect(trip['prix_place'], 300);
    expect(requests(trip), hasLength(2));
    expect(requests(trip).first['actions'], ['accepter', 'refuser']);
    expect(trip.toString(), isNot(contains('code_depart')));
  });

  test('passager sans mode conducteur → 403', () async {
    final passenger = TestEnv.demoSession();
    await expectLater(passenger.driver.publish(body()), throwsA(isA<ForbiddenApiException>()));
  });

  test('accepter retire une place ; trajet complet ; plus d’« accepter » pour les autres', () async {
    final trip = await driver.publish(body());
    final first = requests(trip).first['id'] as int;
    await driver.accept(first);

    final updated = await driver.trip(trip['id'] as int);
    expect(updated['places_restantes'], 0);
    expect(updated['statut'], 'complet');
    expect(requests(updated).first['actions'], ['saisir_code']);
    expect(requests(updated).last['actions'], ['refuser']);
    await expectLater(driver.accept(requests(updated).last['id'] as int), throwsA(isA<ConflictApiException>()));
  });

  test('code de départ : essais limités, puis en_cours et « terminer »', () async {
    final trip = await driver.publish(body());
    final id = requests(trip).first['id'] as int;
    await driver.accept(id);

    await expectLater(
      driver.submitCode(id, '0000'),
      throwsA(isA<BadRequestApiException>().having((e) => e.message, 'message', 'Code incorrect. 4 essais restants.')),
    );
    await driver.submitCode(id, DemoAccount.fakePassengerCode);

    final updated = await driver.trip(trip['id'] as int);
    expect(requests(updated).first['statut'], 'en_cours');
    expect(updated['statut'], 'en_cours');
    expect(updated['actions'], contains('terminer'));
  });

  test('5 codes faux → 429', () async {
    final trip = await driver.publish(body());
    final id = requests(trip).first['id'] as int;
    await driver.accept(id);
    for (var i = 0; i < FakeDriver.maxCodeAttempts; i++) {
      await expectLater(driver.submitCode(id, '0000'), throwsA(isA<BadRequestApiException>()));
    }
    await expectLater(driver.submitCode(id, DemoAccount.fakePassengerCode), throwsA(isA<TooManyAttemptsApiException>()));
  });

  test('absence : refusée avant départ + tolérance, acceptée ensuite avec la position', () async {
    final trip = await driver.publish(body());
    final id = requests(trip).first['id'] as int;
    await driver.accept(id);

    await expectLater(driver.declareAbsence(id, lat: 6.166, lng: 1.165), throwsA(isA<ConflictApiException>()));

    env.now = DateTime.utc(2026, 10, 8, 7, 41); // départ 07:30 + 10 min
    await driver.declareAbsence(id, lat: 6.166, lng: 1.165);
    expect(requests(await driver.trip(trip['id'] as int)).first['statut'], 'absent');
  });

  test('terminer : passagers terminés, économies du mois augmentées', () async {
    expect((await driver.savings())['total'], 18500);
    final trip = await driver.publish(body());
    final id = requests(trip).first['id'] as int;
    await driver.accept(id);
    await driver.submitCode(id, DemoAccount.fakePassengerCode);

    final finished = await driver.finishTrip(trip['id'] as int);
    expect(finished['statut'], 'termine');
    expect(finished['economie'], 300);
    expect(requests(finished).first['statut'], 'terminee');

    final savings = await driver.savings();
    expect(savings['total'], 18800);
    expect(savings['places'], 25);
    expect(savings['mois'], '2026-10');
  });

  test('annuler le trajet : demandes annulées', () async {
    final trip = await driver.publish(body());
    final cancelled = await driver.cancelTrip(trip['id'] as int);
    expect(cancelled['statut'], 'annule');
    expect(requests(cancelled).every((r) => r['statut'] == 'annulee'), isTrue);
    expect(cancelled['actions'], isEmpty);
  });
}
