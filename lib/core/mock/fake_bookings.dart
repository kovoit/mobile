import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_exception.dart';
import 'fake_backend.dart';
import 'fake_trips.dart';

final fakeBookingsProvider = Provider<FakeBookings>((ref) => FakeBookings(ref.watch(fakeBackendProvider)));

/// Règles **serveur** simulées des réservations et du paiement (docs/api/bookings.md).
/// Jamais utilisé avec le vrai backend.
class FakeBookings {
  FakeBookings(this._backend);

  final FakeBackend _backend;
  final math.Random _random = math.Random(42);

  static const int delaiAnnulationMin = 30; // paramètre administrateur (PRD §10)

  DateTime get _now => _backend.clock().toUtc();

  // ------------------------------------------------------------------ API passager

  Future<Map<String, dynamic>> request({
    required int tripId,
    required int places,
    required int pickupPointId,
    required String method,
  }) async {
    await _backend.wait();
    final userId = await _backend.currentUserId();
    final user = _backend.userJson(userId);
    if (user['statut_compte'] == 'suspendu') throw const ForbiddenApiException('Compte suspendu : réservation impossible.');
    if (user['kyc_passager'] != 'verifie') {
      throw const ForbiddenApiException('Votre identité doit être vérifiée pour réserver.');
    }
    final trip = FakeTrips.tripById(tripId, places: places);
    if (trip == null) throw const NotFoundApiException('Ce trajet n’est plus disponible.');
    if (places > (trip['places_restantes'] as int)) {
      throw const ConflictApiException('Il ne reste plus assez de places sur ce trajet.');
    }
    final duplicate = _backend.bookings.values.any(
      (b) => b['passager_id'] == userId && b['trajet_id'] == tripId && _isActive(b['statut'] as String),
    );
    if (duplicate) throw const ConflictApiException('Vous avez déjà une demande en cours sur ce trajet.');

    final id = _backend.nextBookingId++;
    final departure = DateTime.parse(trip['depart_le'] as String);
    _backend.bookings[id] = {
      'id': id,
      'passager_id': userId,
      'trajet_id': tripId,
      'nb_places': places,
      'point_prise_en_charge_id': pickupPointId,
      'statut': 'demandee',
      'code_depart': null,
      'prix_total': trip['prix_total'],
      'frais_service': (trip['frais_service'] as int) * places,
      'paiement': {
        'methode': method,
        'statut': method == 'especes' ? 'non_requis' : 'a_payer',
        'montant': trip['prix_total'],
        'telephone': null,
        'reference': null,
        'message': null,
      },
      'annulation_gratuite_jusqu_au':
          departure.subtract(const Duration(minutes: delaiAnnulationMin)).toIso8601String(),
      'annulation_tardive': false,
      'cree_le': _now.toIso8601String(),
      '_relectures_paiement': 0,
    };
    return _json(id);
  }

  Future<List<Map<String, dynamic>>> listMine() async {
    await _backend.wait();
    final userId = await _backend.currentUserId();
    final mine = _backend.bookings.values.where((b) => b['passager_id'] == userId).toList()
      ..sort((a, b) => (b['cree_le'] as String).compareTo(a['cree_le'] as String));
    return [for (final b in mine) _json(b['id'] as int)];
  }

  Future<Map<String, dynamic>> get(int id) async {
    await _backend.wait();
    final booking = await _owned(id);
    _advancePayment(booking);
    return _json(id);
  }

  Future<Map<String, dynamic>> cancel(int id) async {
    await _backend.wait();
    final booking = await _owned(id);
    if (!['demandee', 'acceptee'].contains(booking['statut'])) {
      throw const ConflictApiException('Cette réservation ne peut plus être annulée.');
    }
    final limit = DateTime.parse(booking['annulation_gratuite_jusqu_au'] as String);
    final payment = booking['paiement'] as Map<String, dynamic>;
    booking
      ..['statut'] = 'annulee'
      ..['code_depart'] = null
      ..['annulation_tardive'] = _now.isAfter(limit);
    if (payment['statut'] == 'reussi') payment['statut'] = 'rembourse';
    if (payment['statut'] == 'a_payer' || payment['statut'] == 'en_attente') payment['statut'] = 'non_requis';
    return _json(id);
  }

  Future<Map<String, dynamic>> pay(int id, {required String telephone}) async {
    await _backend.wait();
    final booking = await _owned(id);
    final payment = booking['paiement'] as Map<String, dynamic>;
    if (booking['statut'] != 'acceptee' || !['a_payer', 'echoue'].contains(payment['statut'])) {
      throw const ConflictApiException('Aucun paiement n’est attendu pour cette réservation.');
    }
    final isFlooz = payment['methode'] == 'flooz';
    payment
      ..['statut'] = 'en_attente'
      ..['telephone'] = telephone
      ..['reference'] = '${isFlooz ? 'FLZ' : 'MIX'}-${1000000 + _random.nextInt(8999999)}'
      ..['message'] = 'Validez le paiement sur votre téléphone (code secret ${isFlooz ? 'Flooz' : 'Mixx'}).';
    booking['_relectures_paiement'] = 1; // confirmé par « l'opérateur » à la relecture suivante
    return _json(id);
  }

  Future<Map<String, dynamic>> share(int id) async {
    await _backend.wait();
    final booking = await _owned(id);
    if (!['acceptee', 'en_cours'].contains(booking['statut'])) {
      throw const ConflictApiException('Le partage est possible une fois la réservation acceptée.');
    }
    final trip = FakeTrips.tripById(booking['trajet_id'] as int)!;
    return {
      'url': 'https://kovoit.tg/t/${id.toRadixString(36)}${_random.nextInt(1 << 20).toRadixString(36)}',
      'expire_le': DateTime.parse(trip['arrivee_estimee_le'] as String).add(const Duration(hours: 3)).toIso8601String(),
    };
  }

  // ------------------------------------------------------------------ Simulation du conducteur (démo)

  Future<void> simulateDriverAccepts(int id) async {
    final booking = _backend.bookings[id]!;
    if (booking['statut'] != 'demandee') return;
    final pickup = _pickup(booking);
    booking
      ..['statut'] = 'acceptee'
      ..['code_depart'] = (1000 + _random.nextInt(9000)).toString()
      ..['position_conducteur'] = {
        'lat': (pickup['lat'] as double) - 0.004,
        'lng': (pickup['lng'] as double) + 0.003,
        'maj_le': _now.toIso8601String(),
      }
      ..['arrivee_conducteur_min'] = 3;
  }

  Future<void> simulateDriverRefuses(int id) async {
    final booking = _backend.bookings[id]!;
    if (booking['statut'] == 'demandee') booking['statut'] = 'refusee';
  }

  /// Le conducteur a saisi le bon code de départ (CA7).
  Future<void> simulatePickup(int id) async {
    final booking = _backend.bookings[id]!;
    if (booking['statut'] != 'acceptee') return;
    booking
      ..['statut'] = 'en_cours'
      ..['code_depart'] = null
      ..['arrivee_conducteur_min'] = null;
  }

  // ------------------------------------------------------------------ Outils

  static bool _isActive(String status) => ['demandee', 'acceptee', 'en_cours'].contains(status);

  Future<Map<String, dynamic>> _owned(int id) async {
    final userId = await _backend.currentUserId();
    final booking = _backend.bookings[id];
    if (booking == null || booking['passager_id'] != userId) {
      throw const NotFoundApiException('Réservation introuvable.');
    }
    return booking;
  }

  void _advancePayment(Map<String, dynamic> booking) {
    final payment = booking['paiement'] as Map<String, dynamic>;
    if (payment['statut'] != 'en_attente') return;
    final remaining = booking['_relectures_paiement'] as int;
    if (remaining > 0) {
      booking['_relectures_paiement'] = remaining - 1;
      return;
    }
    payment
      ..['statut'] = 'reussi'
      ..['message'] = null;
  }

  Map<String, dynamic> _pickup(Map<String, dynamic> booking) {
    final trip = FakeTrips.tripById(booking['trajet_id'] as int)!;
    final points = (trip['points_prise_en_charge'] as List).cast<Map<String, dynamic>>();
    return points.firstWhere((p) => p['id'] == booking['point_prise_en_charge_id'], orElse: () => points.first);
  }

  /// Vue renvoyée au **passager** : actions possibles et données sensibles selon le statut.
  Map<String, dynamic> _json(int id) {
    final b = _backend.bookings[id]!;
    final status = b['statut'] as String;
    final payment = b['paiement'] as Map<String, dynamic>;
    final trip = FakeTrips.tripById(b['trajet_id'] as int, places: b['nb_places'] as int)!
      ..['point_correspondant_id'] = b['point_prise_en_charge_id'];
    final driverId = (trip['conducteur'] as Map)['id'];
    final accepted = status == 'acceptee';
    final ongoing = accepted || status == 'en_cours';

    return {
      'id': id,
      'trajet': trip,
      'nb_places': b['nb_places'],
      'point_prise_en_charge_id': b['point_prise_en_charge_id'],
      'statut': status,
      'code_depart': accepted ? b['code_depart'] : null,
      'prix_total': b['prix_total'],
      'frais_service': b['frais_service'],
      'paiement': Map.of(payment),
      'annulation_gratuite_jusqu_au': b['annulation_gratuite_jusqu_au'],
      'annulation_tardive': b['annulation_tardive'],
      'conducteur_telephone': ongoing ? '+22890000$driverId' : null,
      'position_conducteur': accepted ? b['position_conducteur'] : null,
      'arrivee_conducteur_min': accepted ? b['arrivee_conducteur_min'] : null,
      'actions': [
        if (status == 'demandee' || accepted) 'annuler',
        if (accepted && ['a_payer', 'echoue'].contains(payment['statut'])) 'payer',
        if (ongoing) 'partager',
        if (ongoing) 'appeler',
      ],
      'cree_le': b['cree_le'],
    };
  }
}
