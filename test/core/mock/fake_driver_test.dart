import 'package:flutter_test/flutter_test.dart';
import 'package:kovoit/core/config/demo_account.dart';
import 'package:kovoit/core/mock/fake_driver.dart';
import 'package:kovoit/core/network/api_exception.dart';
import 'package:kovoit/features/driver/data/dto/driver_dto.dart';

import '../../helpers/test_app.dart';

/// Le conducteur simulé doit respecter le contrat du vrai backend (TrajetConducteurSerializer,
/// ReservationConducteurSerializer, /moi/economies/) : la démo et les tests de widgets en dépendent.
void main() {
  late TestEnv env;
  late FakeDriver driver;

  setUp(() {
    env = TestEnv.driverSession(); // 07:20 le 08/10/2026
    driver = env.driver;
  });

  Map<String, dynamic> body({int places = 1, List<Map<String, dynamic>>? points, DateTime? when}) => {
        'vehicule_id': 'v-2',
        'depart_lat': 6.1660,
        'depart_lng': 1.1650,
        'depart_libelle': 'Carrefour Franciscain',
        'arrivee_lat': 6.1680,
        'arrivee_lng': 1.2140,
        'arrivee_libelle': 'Université de Lomé · Entrée sud',
        'depart_le': (when ?? DateTime.utc(2026, 10, 8, 7, 30)).toIso8601String(),
        'places': places,
        'points': points ?? [
          {'lat': 6.1660, 'lng': 1.1650, 'libelle': 'Carrefour Franciscain'},
        ],
      };

  Future<List<Map<String, dynamic>>> requests(Map<String, dynamic> trip) => driver.requests(trip['id'] as String);

  test('publication : erreurs métier du backend', () async {
    await expectLater(
      driver.publish(body(when: DateTime.utc(2026, 10, 8, 7))),
      throwsA(isA<BadRequestApiException>().having((e) => e.code, 'code', 'DEPART_PASSE')),
    );
    await expectLater(
      driver.publish(body(places: 5)),
      throwsA(isA<BadRequestApiException>().having((e) => e.code, 'code', 'PLACES_INVALIDES')),
    );
  });

  test('publication : prix fixé par Kovoit, demandes fictives, aucun code de départ exposé', () async {
    final trip = await driver.publish(body());
    expect(trip['statut'], 'publie');
    expect(trip['prix_place'], FakeDriver.prixSimulation);
    expect(trip['nb_demandes'], 2);
    final dto = DriverTripDto.fromJson(trip).toEntity();
    expect(dto.id, startsWith('trajet-pub-'));
    final reqs = await requests(trip);
    expect(reqs, hasLength(2));
    expect(reqs.toString(), isNot(contains('code_depart')));
    expect(DriverRequestDto.fromJson(reqs.first).toEntity().montant, FakeDriver.prixSimulation);
  });

  test('sans KYC conducteur ni véhicule → 403', () async {
    final passenger = TestEnv.demoSession();
    await expectLater(passenger.driver.publish(body()), throwsA(isA<ForbiddenApiException>()));
  });

  test('accepter retire une place ; trajet complet ; plus de place pour les autres', () async {
    final trip = await driver.publish(body());
    final reqs = await requests(trip);
    await driver.accept(reqs.first['id'] as String);

    final updated = await driver.trip(trip['id'] as String);
    expect(updated['places_restantes'], 0);
    expect(updated['statut'], 'complet');
    await expectLater(
      driver.accept(reqs.last['id'] as String),
      throwsA(isA<ConflictApiException>().having((e) => e.code, 'code', 'PLUS_DE_PLACE')),
    );
  });

  test('code de départ : essais comptés, puis en_cours', () async {
    final trip = await driver.publish(body());
    final id = (await requests(trip)).first['id'] as String;
    await driver.accept(id);

    await expectLater(
      driver.submitCode(id, '0000'),
      throwsA(isA<BadRequestApiException>().having((e) => e.code, 'code', 'CODE_DEPART_INVALIDE')),
    );
    await driver.submitCode(id, DemoAccount.fakePassengerCode);

    expect((await requests(trip)).first['statut'], 'en_cours');
    expect((await driver.trip(trip['id'] as String))['statut'], 'en_cours');
  });

  test('5 codes faux → code bloqué', () async {
    final trip = await driver.publish(body());
    final id = (await requests(trip)).first['id'] as String;
    await driver.accept(id);
    for (var i = 0; i < FakeDriver.maxCodeAttempts; i++) {
      await expectLater(driver.submitCode(id, '0000'), throwsA(isA<BadRequestApiException>()));
    }
    await expectLater(
      driver.submitCode(id, DemoAccount.fakePassengerCode),
      throwsA(isA<ConflictApiException>().having((e) => e.code, 'code', 'CODE_DEPART_BLOQUE')),
    );
  });

  test('absence : refusée avant départ + tolérance, acceptée ensuite, conducteur crédité', () async {
    final trip = await driver.publish(body());
    final id = (await requests(trip)).first['id'] as String;
    await driver.accept(id);

    await expectLater(
      driver.declareAbsence(id, lat: 6.166, lng: 1.165),
      throwsA(isA<ConflictApiException>().having((e) => e.code, 'code', 'ABSENCE_PREMATUREE')),
    );

    env.now = DateTime.utc(2026, 10, 8, 7, 41); // départ 07:30 + 10 min
    await driver.declareAbsence(id, lat: 6.166, lng: 1.165);
    expect((await requests(trip)).first['statut'], 'absent');
    expect((await driver.savings())['mois_en_cours'], 18500 + FakeDriver.prixSimulation);
  });

  test('terminer : refusé tant qu’un passager accepté n’est pas pris en charge', () async {
    final trip = await driver.publish(body());
    final id = (await requests(trip)).first['id'] as String;
    await driver.accept(id);
    await expectLater(
      driver.finishTrip(trip['id'] as String),
      throwsA(isA<ConflictApiException>().having((e) => e.code, 'code', 'PASSAGERS_EN_ATTENTE')),
    );
  });

  test('terminer : passagers terminés, économies par trajet et du mois', () async {
    expect((await driver.savings())['mois_en_cours'], 18500);
    final trip = await driver.publish(body());
    final id = (await requests(trip)).first['id'] as String;
    await driver.accept(id);
    await driver.submitCode(id, DemoAccount.fakePassengerCode);

    final finished = await driver.finishTrip(trip['id'] as String);
    expect(finished['statut'], 'termine');
    expect((await requests(trip)).first['statut'], 'terminee');

    final savings = SavingsDto.fromJson(await driver.savings()).toEntity();
    expect(savings.moisEnCours, 18800);
    expect(savings.parTrajet.where((t) => t.tripId == trip['id']).single.montant, 300);
  });

  test('annuler le trajet : demandes annulées', () async {
    final trip = await driver.publish(body());
    final cancelled = await driver.cancelTrip(trip['id'] as String);
    expect(cancelled['statut'], 'annule');
    expect((await requests(trip)).every((r) => r['statut'] == 'annulee'), isTrue);
  });
}
