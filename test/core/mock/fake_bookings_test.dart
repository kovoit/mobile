import 'package:flutter_test/flutter_test.dart';
import 'package:kovoit/core/mock/fake_bookings.dart';
import 'package:kovoit/core/mock/fake_trips.dart';
import 'package:kovoit/core/network/api_exception.dart';

import '../../helpers/test_app.dart';

/// Le backend simulé doit respecter le contrat docs/api/bookings.md : la démo et les tests
/// de widgets en dépendent.
void main() {
  late TestEnv env;
  late FakeBookings bookings;
  late int tripId;

  setUp(() {
    env = TestEnv.demoSession(); // KYC passager vérifié, 07:20 le 08/10/2026
    bookings = env.bookings;
    final search = FakeTrips.search(
      departLat: 6.1660,
      departLng: 1.1650,
      arriveeLat: 6.1680,
      arriveeLng: 1.2140,
      dateHeure: DateTime.utc(2026, 10, 8, 7, 30),
      places: 1,
      typeVehicule: 'voiture',
    );
    tripId = ((search['resultats'] as List).first as Map)['id'] as int; // Koffi, 07:30, 2 places
  });

  Future<Map<String, dynamic>> request({String method = 'especes', int places = 1}) =>
      bookings.request(tripId: tripId, places: places, pickupPointId: 1, method: method);

  test('demande : statut demandee, annulation seule possible, pas de code', () async {
    final booking = await request();
    expect(booking['statut'], 'demandee');
    expect(booking['actions'], ['annuler']);
    expect(booking['code_depart'], isNull);
    expect((booking['paiement'] as Map)['statut'], 'non_requis');
  });

  test('KYC passager non vérifié → 403', () async {
    final newcomer = TestEnv.newUserSession();
    await expectLater(
      newcomer.bookings.request(tripId: tripId, places: 1, pickupPointId: 1, method: 'especes'),
      throwsA(isA<ForbiddenApiException>()),
    );
  });

  test('doublon et places insuffisantes → 409', () async {
    await request();
    await expectLater(request(), throwsA(isA<ConflictApiException>()));
    await expectLater(request(places: 3), throwsA(isA<ConflictApiException>()));
  });

  test('acceptation : code à 4 chiffres pour le passager, téléphone du conducteur, partage', () async {
    final id = (await request())['id'] as int;
    await bookings.simulateDriverAccepts(id);

    final booking = await bookings.get(id);
    expect(booking['statut'], 'acceptee');
    expect(booking['code_depart'], matches(RegExp(r'^\d{4}$')));
    expect(booking['conducteur_telephone'], isNotNull);
    expect(booking['actions'], containsAll(['annuler', 'partager', 'appeler']));
    expect(booking['actions'], isNot(contains('payer')), reason: 'paiement en espèces');
  });

  test('Flooz : à payer après acceptation, en attente, puis réussi à la relecture', () async {
    final id = (await request(method: 'flooz'))['id'] as int;
    expect(((await bookings.get(id))['paiement'] as Map)['statut'], 'a_payer');
    await expectLater(bookings.pay(id, telephone: '+22896123456'), throwsA(isA<ConflictApiException>()),
        reason: 'pas de paiement avant acceptation');

    await bookings.simulateDriverAccepts(id);
    expect((await bookings.get(id))['actions'], contains('payer'));

    final pending = await bookings.pay(id, telephone: '+22896123456');
    expect((pending['paiement'] as Map)['statut'], 'en_attente');
    expect((pending['paiement'] as Map)['reference'], startsWith('FLZ-'));

    expect(((await bookings.get(id))['paiement'] as Map)['statut'], 'en_attente');
    expect(((await bookings.get(id))['paiement'] as Map)['statut'], 'reussi');
  });

  test('annulation : tardive après la limite, remboursement si déjà payé', () async {
    final id = (await request(method: 'mixx'))['id'] as int;
    await bookings.simulateDriverAccepts(id);
    await bookings.pay(id, telephone: '+22890123456');
    await bookings.get(id);
    await bookings.get(id); // paiement réussi

    final cancelled = await bookings.cancel(id); // 07:20 > 07:00 (départ 07:30 − 30 min)
    expect(cancelled['statut'], 'annulee');
    expect(cancelled['annulation_tardive'], isTrue);
    expect((cancelled['paiement'] as Map)['statut'], 'rembourse');
    expect(cancelled['code_depart'], isNull);
  });

  test('annulation gratuite avant la limite', () async {
    env.now = DateTime.utc(2026, 10, 8, 6, 30);
    final id = (await request())['id'] as int;
    expect((await bookings.cancel(id))['annulation_tardive'], isFalse);
  });

  test('prise en charge : en_cours, le code disparaît', () async {
    final id = (await request())['id'] as int;
    await bookings.simulateDriverAccepts(id);
    await bookings.simulatePickup(id);
    final booking = await bookings.get(id);
    expect(booking['statut'], 'en_cours');
    expect(booking['code_depart'], isNull);
    expect(booking['actions'], isNot(contains('annuler')));
  });
}
