import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_exception.dart';
import 'fake_backend.dart';
import 'fake_trips.dart';
import 'fake_wallet.dart';

final fakeBookingsProvider = Provider<FakeBookings>(
  (ref) => FakeBookings(ref.watch(fakeBackendProvider), ref.watch(fakeWalletProvider)),
);

/// Règles **serveur** simulées des réservations (`Env.useMockApi`), au format du backend
/// (ReservationPassagerSerializer). Une réservation = une place ; le montant est bloqué sur le
/// portefeuille à la demande, débité à la prise en charge. Jamais utilisé avec le vrai backend.
class FakeBookings {
  FakeBookings(this._backend, this._wallet);

  final FakeBackend _backend;
  final FakeWallet _wallet;
  final math.Random _random = math.Random(42);

  static const int delaiAnnulationMin = 30; // paramètre administrateur `delai_annulation_min`

  DateTime get _now => _backend.clock().toUtc();

  // ------------------------------------------------------------------ API passager

  /// `POST /reservations/` : `trajet_id`, `point_id`, `arrivee_lat`, `arrivee_lng`, `arrivee_libelle`.
  Future<Map<String, dynamic>> request({
    required String tripId,
    required String pickupPointId,
    required double arriveeLat,
    required double arriveeLng,
    String arriveeLibelle = '',
  }) async {
    await _backend.wait();
    final userId = await _backend.currentUserId();
    final user = _backend.userJson(userId);
    if (user['statut_compte'] == 'suspendu') {
      throw const ForbiddenApiException('Votre compte est suspendu : action impossible.', code: 'COMPTE_SUSPENDU');
    }
    if (user['kyc_passager'] != 'verifie') {
      throw const ForbiddenApiException('Faites vérifier votre identité pour réserver.', code: 'KYC_PASSAGER_REQUIS');
    }
    final trip = FakeTrips.tripById(tripId);
    if (trip == null) throw const NotFoundApiException('Trajet introuvable.');
    final points = (trip['points'] as List).cast<Map<String, dynamic>>();
    if (!points.any((p) => p['id'] == pickupPointId)) {
      throw const NotFoundApiException('Point de prise en charge introuvable.');
    }
    final duplicate = _backend.bookings.values.any(
      (b) => b['passager_id'] == userId && b['trajet_id'] == tripId && _isActive(b['statut'] as String),
    );
    if (duplicate) throw const ConflictApiException('Vous avez déjà une réservation sur ce trajet.', code: 'DEJA_RESERVE');

    final montant = (trip['prix_place'] as int) + (trip['frais_service'] as int);
    final complement = _wallet.complementFor(userId, montant);
    if (complement > 0) {
      throw ConflictApiException(
        'Solde insuffisant : rechargez $complement F CFA par Flooz ou Mixx, puis réservez.',
        code: 'SOLDE_INSUFFISANT',
        details: {
          'complement_a_payer': complement,
          'recharge_suggeree': complement < FakeTrips.rechargeMin ? FakeTrips.rechargeMin : complement,
          'moyens_paiement': const ['flooz', 'mixx'],
          'recharge_requise': true,
        },
      );
    }

    final id = 'resa-${_backend.nextBookingId++}';
    _backend.bookings[id] = {
      'id': id,
      'passager_id': userId,
      'trajet_id': tripId,
      'point_id': pickupPointId,
      'arrivee_lat': arriveeLat,
      'arrivee_lng': arriveeLng,
      'arrivee_libelle': arriveeLibelle,
      'statut': 'demandee',
      'code_depart': null,
      'prix': trip['prix_place'],
      'frais_service': trip['frais_service'],
      'montant_total': montant,
      'annulation_tardive': false,
      'cree_le': _now.toIso8601String(),
    };
    _wallet.write(userId, 'blocage', montant, reservationId: id);
    return _json(id);
  }

  /// `GET /reservations/` : réservations du passager, plus récentes d'abord.
  Future<List<Map<String, dynamic>>> listMine() async {
    await _backend.wait();
    final userId = await _backend.currentUserId();
    final mine = _backend.bookings.values.where((b) => b['passager_id'] == userId).toList()
      ..sort((a, b) => (b['cree_le'] as String).compareTo(a['cree_le'] as String));
    return [for (final b in mine) _json(b['id'] as String)];
  }

  Future<Map<String, dynamic>> get(String id) async {
    await _backend.wait();
    await _owned(id);
    return _json(id);
  }

  Future<Map<String, dynamic>> cancel(String id) async {
    await _backend.wait();
    final booking = await _owned(id);
    if (!['demandee', 'acceptee'].contains(booking['statut'])) {
      throw const ConflictApiException('Cette réservation ne peut plus être annulée.', code: 'NON_ANNULABLE');
    }
    final departure = DateTime.parse(_trip(booking)['depart_le'] as String);
    final tardive = booking['statut'] == 'acceptee' &&
        departure.difference(_now) < const Duration(minutes: delaiAnnulationMin);
    booking
      ..['statut'] = 'annulee'
      ..['code_depart'] = null
      ..['annulation_tardive'] = tardive
      ..['annulee_le'] = _now.toIso8601String();
    _unblock(booking);
    return _json(id);
  }

  /// `POST /reservations/{id}/partage/` → `{jeton, chemin}`.
  Future<Map<String, dynamic>> share(String id) async {
    await _backend.wait();
    final booking = await _owned(id);
    if (!['acceptee', 'en_cours'].contains(booking['statut'])) {
      throw const ConflictApiException(
        'Le partage est possible une fois la réservation acceptée.',
        code: 'PARTAGE_IMPOSSIBLE',
      );
    }
    final jeton = '${id.hashCode.toRadixString(36)}${_random.nextInt(1 << 20).toRadixString(36)}';
    return {'jeton': jeton, 'chemin': '/api/v1/partage/$jeton/'};
  }

  /// `POST /reservations/{id}/confirmer-arrivee/` : `terminee` → `cloturee`.
  Future<Map<String, dynamic>> confirm(String id) async {
    await _backend.wait();
    final booking = await _owned(id);
    if (booking['statut'] != 'terminee') {
      throw const ConflictApiException('Seul un trajet terminé peut être confirmé.', code: 'CONFIRMATION_IMPOSSIBLE');
    }
    booking
      ..['statut'] = 'cloturee'
      ..['cloturee_le'] = _now.toIso8601String();
    return _json(id);
  }

  // ------------------------------------------------------------------ Simulation du conducteur (démo)

  Future<void> simulateDriverAccepts(String id) async {
    final booking = _backend.bookings[id]!;
    if (booking['statut'] != 'demandee') return;
    booking
      ..['statut'] = 'acceptee'
      ..['code_depart'] = (1000 + _random.nextInt(9000)).toString()
      ..['acceptee_le'] = _now.toIso8601String();
  }

  Future<void> simulateDriverRefuses(String id) async {
    final booking = _backend.bookings[id]!;
    if (booking['statut'] != 'demandee') return;
    booking
      ..['statut'] = 'refusee'
      ..['refusee_le'] = _now.toIso8601String();
    _unblock(booking);
  }

  /// Le conducteur a saisi le bon code de départ : le montant bloqué est débité.
  Future<void> simulatePickup(String id) async {
    final booking = _backend.bookings[id]!;
    if (booking['statut'] != 'acceptee') return;
    booking
      ..['statut'] = 'en_cours'
      ..['code_depart'] = null
      ..['en_cours_le'] = _now.toIso8601String();
    final userId = booking['passager_id'] as int;
    _unblock(booking);
    _wallet.write(userId, 'debit', booking['montant_total'] as int, reservationId: id);
  }

  /// Le conducteur a terminé le trajet : le passager doit confirmer son arrivée.
  Future<void> simulateTripFinished(String id) async {
    final booking = _backend.bookings[id]!;
    if (booking['statut'] != 'en_cours') return;
    booking
      ..['statut'] = 'terminee'
      ..['terminee_le'] = _now.toIso8601String();
  }

  // ------------------------------------------------------------------ Outils

  static bool _isActive(String status) => ['demandee', 'acceptee', 'en_cours'].contains(status);

  void _unblock(Map<String, dynamic> booking) {
    final userId = booking['passager_id'] as int;
    final id = booking['id'] as String;
    _wallet.write(userId, 'deblocage', _wallet.blockedFor(userId, id), reservationId: id);
  }

  Map<String, dynamic> _trip(Map<String, dynamic> booking) => FakeTrips.tripById(booking['trajet_id'] as String)!;

  Future<Map<String, dynamic>> _owned(String id) async {
    final userId = await _backend.currentUserId();
    final booking = _backend.bookings[id];
    if (booking == null || booking['passager_id'] != userId) {
      throw const NotFoundApiException('Réservation introuvable.');
    }
    return booking;
  }

  /// Vue du **passager** : seule vue qui contient le code de départ (réservation acceptée).
  Map<String, dynamic> _json(String id) {
    final b = _backend.bookings[id]!;
    final trip = _trip(b)..remove('paiement');
    final points = (trip['points'] as List).cast<Map<String, dynamic>>();
    final status = b['statut'] as String;
    return {
      'id': id,
      'trajet': trip,
      'statut': status,
      'point': points.firstWhere((p) => p['id'] == b['point_id'], orElse: () => points.first),
      'arrivee_lat': b['arrivee_lat'],
      'arrivee_lng': b['arrivee_lng'],
      'arrivee_libelle': b['arrivee_libelle'],
      'distance_km': trip['distance_km'],
      'prix': b['prix'],
      'frais_service': b['frais_service'],
      'montant_total': b['montant_total'],
      'moyen_paiement': '',
      'complement_paye': 0,
      'annulation_tardive': b['annulation_tardive'],
      'cree_le': b['cree_le'],
      for (final champ in ['acceptee_le', 'refusee_le', 'annulee_le', 'en_cours_le', 'terminee_le', 'cloturee_le'])
        champ: b[champ],
      'code_depart': status == 'acceptee' ? b['code_depart'] : null,
    };
  }
}
