import 'package:flutter_test/flutter_test.dart';
import 'package:kovoit/core/mock/fake_bookings.dart';
import 'package:kovoit/core/mock/fake_trips.dart';
import 'package:kovoit/core/network/api_exception.dart';
import 'package:kovoit/features/booking/data/dto/booking_dto.dart';

import '../../helpers/test_app.dart';

/// Le backend simulé doit respecter le contrat du vrai backend (ReservationPassagerSerializer,
/// portefeuille) : la démo et les tests de widgets en dépendent.
void main() {
  late TestEnv env;
  late FakeBookings bookings;
  late String tripId;
  late String pickupId;

  setUp(() {
    env = TestEnv.demoSession(); // KYC passager vérifié, 2 000 F sur le portefeuille, 07:20 le 08/10/2026
    bookings = env.bookings;
    final first = FakeTrips.search(
      departLat: 6.1660,
      departLng: 1.1650,
      arriveeLat: 6.1680,
      arriveeLng: 1.2140,
      dateHeure: DateTime.utc(2026, 10, 8, 7, 30),
    ).first; // Koffi, 07:30
    tripId = (first['trajet'] as Map)['id'] as String;
    pickupId = (first['point_propose'] as Map)['id'] as String;
  });

  Future<Map<String, dynamic>> request() =>
      bookings.request(tripId: tripId, pickupPointId: pickupId, arriveeLat: 6.168, arriveeLng: 1.214);

  int disponible() => env.wallet.balanceOf(1)['disponible']!;

  test('demande : statut demandee, montant bloqué sur le portefeuille, pas de code', () async {
    final booking = await request();
    expect(booking['statut'], 'demandee');
    expect(booking['code_depart'], isNull);
    expect(booking['montant_total'], 300);
    expect(env.wallet.balanceOf(1), {'total': 2000, 'bloque': 300, 'disponible': 1700});
    expect(BookingDto.fromJson(booking).toEntity().id, startsWith('resa-'));
  });

  test('KYC passager non vérifié → 403', () async {
    final newcomer = TestEnv.newUserSession();
    await expectLater(
      newcomer.bookings.request(tripId: tripId, pickupPointId: pickupId, arriveeLat: 6.168, arriveeLng: 1.214),
      throwsA(isA<ForbiddenApiException>().having((e) => e.code, 'code', 'KYC_PASSAGER_REQUIS')),
    );
  });

  test('doublon → 409 DEJA_RESERVE', () async {
    await request();
    await expectLater(request(), throwsA(isA<ConflictApiException>().having((e) => e.code, 'code', 'DEJA_RESERVE')));
  });

  test('solde insuffisant → 409 avec le complément à recharger', () async {
    env.wallet.write(1, 'retrait', 1900); // il reste 100 F
    await expectLater(
      request(),
      throwsA(
        isA<ConflictApiException>()
            .having((e) => e.code, 'code', 'SOLDE_INSUFFISANT')
            .having((e) => e.details['complement_a_payer'], 'complément', 200)
            .having((e) => e.details['recharge_requise'], 'recharge', true),
      ),
    );
  });

  test('acceptation : code à 4 chiffres pour le passager seulement', () async {
    final id = (await request())['id'] as String;
    await bookings.simulateDriverAccepts(id);

    final booking = await bookings.get(id);
    expect(booking['statut'], 'acceptee');
    expect(booking['code_depart'], matches(RegExp(r'^\d{4}$')));
    expect(booking.containsKey('conducteur_telephone'), isFalse);
  });

  test('refus : le montant bloqué est rendu', () async {
    final id = (await request())['id'] as String;
    await bookings.simulateDriverRefuses(id);
    expect(disponible(), 2000);
  });

  test('annulation tardive après acceptation, montant rendu', () async {
    final id = (await request())['id'] as String;
    await bookings.simulateDriverAccepts(id);

    final cancelled = await bookings.cancel(id); // 07:20, départ 07:30 (< 30 min)
    expect(cancelled['statut'], 'annulee');
    expect(cancelled['annulation_tardive'], isTrue);
    expect(cancelled['code_depart'], isNull);
    expect(disponible(), 2000);
  });

  test('annulation d’une simple demande : jamais tardive', () async {
    final id = (await request())['id'] as String;
    expect((await bookings.cancel(id))['annulation_tardive'], isFalse);
  });

  test('prise en charge : en_cours, le code disparaît, le montant est débité', () async {
    final id = (await request())['id'] as String;
    await bookings.simulateDriverAccepts(id);
    await bookings.simulatePickup(id);
    final booking = await bookings.get(id);
    expect(booking['statut'], 'en_cours');
    expect(booking['code_depart'], isNull);
    expect(env.wallet.balanceOf(1), {'total': 1700, 'bloque': 0, 'disponible': 1700});
    await expectLater(bookings.cancel(id), throwsA(isA<ConflictApiException>()));
  });

  test('partage : chemin relatif au serveur de l’API', () async {
    final id = (await request())['id'] as String;
    await bookings.simulateDriverAccepts(id);
    final link = await bookings.share(id);
    expect(link['chemin'], startsWith('/api/v1/partage/'));
  });
}
