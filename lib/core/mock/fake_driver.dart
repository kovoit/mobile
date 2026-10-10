import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/demo_account.dart';
import '../network/api_exception.dart';
import 'fake_backend.dart';
import 'fake_trips.dart';

final fakeDriverProvider = Provider<FakeDriver>((ref) => FakeDriver(ref.watch(fakeBackendProvider)));

/// Règles **serveur** simulées de l'espace conducteur (docs/api/driver.md).
/// Jamais utilisé avec le vrai backend.
class FakeDriver {
  FakeDriver(this._backend);

  final FakeBackend _backend;

  // Paramètres administrateur (PRD §10).
  static const int toleranceRetardMin = 10;
  static const int maxCodeAttempts = 5;

  DateTime get _now => _backend.clock().toUtc();

  /// Passagers fictifs qui demandent une place dès la publication (démo).
  static const List<Map<String, dynamic>> _fakePassengers = [
    {'id': 31, 'prenom': 'Afi', 'nom': 'Amégan', 'photo': null, 'verifie': true, 'note': 4.8, 'methode': 'flooz'},
    {'id': 32, 'prenom': 'Kossi', 'nom': 'Akakpo', 'photo': null, 'verifie': true, 'note': 4.6, 'methode': 'especes'},
  ];

  // ------------------------------------------------------------------ Droits

  Future<int> _driverId() async {
    final id = await _backend.currentUserId();
    final user = _backend.userJson(id);
    if (user['statut_compte'] == 'suspendu') throw const ForbiddenApiException('Compte suspendu.');
    final allowed = user['kyc_passager'] == 'verifie' &&
        user['kyc_conducteur'] == 'verifie' &&
        user['vehicule_declare'] == true &&
        user['mode_actif'] == 'conducteur';
    if (!allowed) throw const ForbiddenApiException('Passez en mode conducteur pour publier et gérer vos trajets.');
    return id;
  }

  // ------------------------------------------------------------------ Prix

  /// Prix par place selon la grille de la spécification (décision D1 encore ouverte).
  static int priceFor(double km) => km < 5 ? 200 : (km <= 10 ? 300 : 500);

  Future<Map<String, dynamic>> estimate({required Map<String, dynamic> depart, required Map<String, dynamic> arrivee}) async {
    await _backend.wait();
    await _driverId();
    final km = FakeTrips.roadKm(
      (depart['lat'] as num).toDouble(),
      (depart['lng'] as num).toDouble(),
      (arrivee['lat'] as num).toDouble(),
      (arrivee['lng'] as num).toDouble(),
    );
    return {
      'prix_place': priceFor(km),
      'distance_km': double.parse(km.toStringAsFixed(1)),
      'duree_min': (km / 20 * 60).round().clamp(5, 180),
    };
  }

  // ------------------------------------------------------------------ Trajets

  Future<Map<String, dynamic>> publish(Map<String, dynamic> body) async {
    await _backend.wait();
    final driverId = await _driverId();
    final vehicle = _backend.vehicleJson(driverId)!;
    final pickups = (body['points_prise_en_charge'] as List).cast<Map<String, dynamic>>();
    final places = body['places_total'] as int;
    final departure = DateTime.parse(body['depart_le'] as String);
    final maxPlaces = (vehicle['nb_places'] as int) - 1;
    final errors = <String, String>{
      if (pickups.isEmpty || pickups.length > 3) 'points_prise_en_charge': 'Indiquez 1 à 3 points de prise en charge.',
      if (places < 1 || places > maxPlaces) 'places_total': 'Entre 1 et $maxPlaces places pour ce véhicule.',
      if (!departure.isAfter(_now)) 'depart_le': 'Choisissez une heure de départ à venir.',
    };
    if (errors.isNotEmpty) throw BadRequestApiException('Veuillez corriger le trajet.', fieldErrors: errors);

    final depart = body['depart'] as Map<String, dynamic>;
    final arrivee = body['arrivee'] as Map<String, dynamic>;
    final km = FakeTrips.roadKm(
      (depart['lat'] as num).toDouble(),
      (depart['lng'] as num).toDouble(),
      (arrivee['lat'] as num).toDouble(),
      (arrivee['lng'] as num).toDouble(),
    );
    final id = _backend.nextDriverTripId++;
    final trip = <String, dynamic>{
      'id': id,
      'conducteur_id': driverId,
      'depart': depart,
      'arrivee': arrivee,
      'points_prise_en_charge': [
        for (final (index, p) in pickups.indexed) {...p, 'id': id * 10 + index + 1, 'ordre': index + 1},
      ],
      'depart_le': departure.toIso8601String(),
      'places_total': places,
      'places_restantes': places,
      'prix_place': priceFor(km),
      'statut': 'publie',
      'demandes': <Map<String, dynamic>>[],
    };
    _backend.driverTrips[id] = trip;

    // Démo : deux passagers fictifs demandent une place, au premier point de prise en charge.
    final firstPickupId = (trip['points_prise_en_charge'] as List).first['id'];
    for (final passenger in _fakePassengers.take(places + 1)) {
      (trip['demandes'] as List).add({
        'id': _backend.nextDriverRequestId++,
        'passager': {...passenger}..remove('methode'),
        'nb_places': 1,
        'point_prise_en_charge_id': firstPickupId,
        'statut': 'demandee',
        'methode_paiement': passenger['methode'],
        'statut_paiement': passenger['methode'] == 'especes' ? 'non_requis' : 'a_payer',
        'montant': trip['prix_place'],
        '_essais_code': 0,
      });
    }
    return _json(trip);
  }

  Future<List<Map<String, dynamic>>> myTrips() async {
    await _backend.wait();
    final driverId = await _driverId();
    final trips = _backend.driverTrips.values.where((t) => t['conducteur_id'] == driverId).toList()
      ..sort((a, b) => (a['depart_le'] as String).compareTo(b['depart_le'] as String));
    return [for (final t in trips) _json(t)];
  }

  Future<Map<String, dynamic>> trip(int id) async {
    await _backend.wait();
    return _json(await _ownedTrip(id));
  }

  Future<Map<String, dynamic>> cancelTrip(int id) async {
    await _backend.wait();
    final trip = await _ownedTrip(id);
    if (!_tripActions(trip).contains('annuler')) throw const ConflictApiException('Ce trajet ne peut plus être annulé.');
    trip['statut'] = 'annule';
    for (final request in _requests(trip)) {
      if (['demandee', 'acceptee'].contains(request['statut'])) request['statut'] = 'annulee';
    }
    return _json(trip);
  }

  Future<Map<String, dynamic>> finishTrip(int id) async {
    await _backend.wait();
    final trip = await _ownedTrip(id);
    if (!_tripActions(trip).contains('terminer')) {
      throw const ConflictApiException('Le trajet ne peut être terminé qu’après la prise en charge d’un passager.');
    }
    trip['statut'] = 'termine';
    for (final request in _requests(trip)) {
      if (request['statut'] == 'en_cours') request['statut'] = 'terminee';
    }
    final paid = _requests(trip).where((r) => ['terminee', 'absent'].contains(r['statut']));
    _backend.savings.putIfAbsent(trip['conducteur_id'] as int, () => []).add({
      'date': trip['depart_le'],
      'montant': paid.fold<int>(0, (sum, r) => sum + (r['montant'] as int)),
      'places': paid.fold<int>(0, (sum, r) => sum + (r['nb_places'] as int)),
    });
    return _json(trip);
  }

  // ------------------------------------------------------------------ Demandes

  Future<void> accept(int requestId) async {
    await _backend.wait();
    final (trip, request) = await _ownedRequest(requestId);
    if (request['statut'] != 'demandee') throw const ConflictApiException('Cette demande a déjà été traitée.');
    final places = request['nb_places'] as int;
    if ((trip['places_restantes'] as int) < places) {
      throw const ConflictApiException('Il ne reste plus assez de places sur ce trajet.');
    }
    trip['places_restantes'] = (trip['places_restantes'] as int) - places;
    if (trip['places_restantes'] == 0) trip['statut'] = 'complet';
    request['statut'] = 'acceptee';
  }

  Future<void> refuse(int requestId) async {
    await _backend.wait();
    final (_, request) = await _ownedRequest(requestId);
    if (request['statut'] != 'demandee') throw const ConflictApiException('Cette demande a déjà été traitée.');
    request['statut'] = 'refusee';
  }

  Future<void> submitCode(int requestId, String code) async {
    await _backend.wait();
    final (trip, request) = await _ownedRequest(requestId);
    if (request['statut'] != 'acceptee') throw const ConflictApiException('Ce passager n’attend pas de prise en charge.');
    final attempts = request['_essais_code'] as int;
    if (attempts >= maxCodeAttempts) {
      throw const TooManyAttemptsApiException('Trop d’essais. Demandez au passager de contacter le support.');
    }
    // Le vrai serveur compare au hash ; le conducteur n'a jamais accès au code.
    if (code != DemoAccount.fakePassengerCode) {
      request['_essais_code'] = attempts + 1;
      final left = maxCodeAttempts - attempts - 1;
      throw BadRequestApiException(
        'Code incorrect. $left essai${left > 1 ? 's' : ''} restant${left > 1 ? 's' : ''}.',
        fieldErrors: {'code': 'Code incorrect.'},
      );
    }
    request['statut'] = 'en_cours';
    trip['statut'] = 'en_cours';
  }

  Future<void> declareAbsence(int requestId, {required double lat, required double lng}) async {
    await _backend.wait();
    final (trip, request) = await _ownedRequest(requestId);
    if (!_requestActions(trip, request).contains('declarer_absence')) {
      final from = _absenceAllowedFrom(trip);
      throw ConflictApiException(
        'Vous pourrez déclarer une absence à partir de ${from.hour.toString().padLeft(2, '0')}:${from.minute.toString().padLeft(2, '0')}.',
      );
    }
    request
      ..['statut'] = 'absent'
      ..['position_absence'] = {'lat': lat, 'lng': lng, 'le': _now.toIso8601String()};
  }

  // ------------------------------------------------------------------ Économies

  Future<Map<String, dynamic>> savings() async {
    await _backend.wait();
    final driverId = await _driverId();
    final now = _now;
    final lines = (_backend.savings[driverId] ?? const <Map<String, dynamic>>[]).where((line) {
      final date = DateTime.parse(line['date'] as String);
      return date.year == now.year && date.month == now.month;
    });
    return {
      'mois': '${now.year}-${now.month.toString().padLeft(2, '0')}',
      'total': lines.fold<int>(0, (sum, l) => sum + (l['montant'] as int)),
      'places': lines.fold<int>(0, (sum, l) => sum + (l['places'] as int)),
    };
  }

  // ------------------------------------------------------------------ Outils

  List<Map<String, dynamic>> _requests(Map<String, dynamic> trip) =>
      (trip['demandes'] as List).cast<Map<String, dynamic>>();

  DateTime _absenceAllowedFrom(Map<String, dynamic> trip) =>
      DateTime.parse(trip['depart_le'] as String).add(const Duration(minutes: toleranceRetardMin));

  Future<Map<String, dynamic>> _ownedTrip(int id) async {
    final driverId = await _driverId();
    final trip = _backend.driverTrips[id];
    if (trip == null || trip['conducteur_id'] != driverId) throw const NotFoundApiException('Trajet introuvable.');
    return trip;
  }

  Future<(Map<String, dynamic>, Map<String, dynamic>)> _ownedRequest(int requestId) async {
    final driverId = await _driverId();
    for (final trip in _backend.driverTrips.values.where((t) => t['conducteur_id'] == driverId)) {
      for (final request in _requests(trip)) {
        if (request['id'] == requestId) return (trip, request);
      }
    }
    throw const NotFoundApiException('Demande introuvable.');
  }

  List<String> _tripActions(Map<String, dynamic> trip) {
    final status = trip['statut'] as String;
    final beforeDeparture = _now.isBefore(DateTime.parse(trip['depart_le'] as String));
    return [
      if ((status == 'publie' || status == 'complet') && beforeDeparture) 'annuler',
      if (_requests(trip).any((r) => r['statut'] == 'en_cours')) 'terminer',
    ];
  }

  List<String> _requestActions(Map<String, dynamic> trip, Map<String, dynamic> request) {
    final tripOpen = ['publie', 'complet', 'en_cours'].contains(trip['statut']);
    if (!tripOpen) return const [];
    return switch (request['statut']) {
      'demandee' => [
          if ((trip['places_restantes'] as int) >= (request['nb_places'] as int)) 'accepter',
          'refuser',
        ],
      'acceptee' => [
          'saisir_code',
          if (!_now.isBefore(_absenceAllowedFrom(trip))) 'declarer_absence',
        ],
      _ => const [],
    };
  }

  /// Vue renvoyée au **conducteur** : jamais de code de départ.
  Map<String, dynamic> _json(Map<String, dynamic> trip) {
    final paid = _requests(trip).where((r) => ['en_cours', 'terminee', 'absent'].contains(r['statut']));
    return {
      'id': trip['id'],
      'depart': trip['depart'],
      'arrivee': trip['arrivee'],
      'points_prise_en_charge': trip['points_prise_en_charge'],
      'depart_le': trip['depart_le'],
      'places_total': trip['places_total'],
      'places_restantes': trip['places_restantes'],
      'prix_place': trip['prix_place'],
      'statut': trip['statut'],
      'economie': paid.fold<int>(0, (sum, r) => sum + (r['montant'] as int)),
      'demandes': [
        for (final r in _requests(trip))
          {
            'id': r['id'],
            'passager': r['passager'],
            'nb_places': r['nb_places'],
            'point_prise_en_charge_id': r['point_prise_en_charge_id'],
            'statut': r['statut'],
            'methode_paiement': r['methode_paiement'],
            'statut_paiement': r['statut_paiement'],
            'montant': r['montant'],
            'actions': _requestActions(trip, r),
          },
      ],
      'actions': _tripActions(trip),
    };
  }
}
