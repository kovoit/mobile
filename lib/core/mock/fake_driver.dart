import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/demo_account.dart';
import '../network/api_exception.dart';
import 'fake_backend.dart';
import 'fake_trips.dart';

final fakeDriverProvider = Provider<FakeDriver>((ref) => FakeDriver(ref.watch(fakeBackendProvider)));

/// Règles **serveur** simulées de l'espace conducteur (`Env.useMockApi`), au format du backend
/// (TrajetConducteurSerializer, ReservationConducteurSerializer, `/moi/economies/`).
/// Jamais utilisé avec le vrai backend.
class FakeDriver {
  FakeDriver(this._backend);

  final FakeBackend _backend;

  // Paramètres administrateur (valeurs de départ du PRD).
  static const int toleranceRetardMin = 10;
  static const int maxCodeAttempts = 5;
  static const int prixSimulation = 300;

  DateTime get _now => _backend.clock().toUtc();

  /// Passagers fictifs qui demandent une place dès la publication (démo).
  static const List<Map<String, dynamic>> _fakePassengers = [
    {'id': 'u31', 'prenom': 'Afi', 'nom': 'Amégan', 'note': 4.8},
    {'id': 'u32', 'prenom': 'Kossi', 'nom': 'Akakpo', 'note': 4.6},
  ];

  // ------------------------------------------------------------------ Droits

  Future<int> _driverId() async {
    final id = await _backend.currentUserId();
    final user = _backend.userJson(id);
    if (user['statut_compte'] == 'suspendu') {
      throw const ForbiddenApiException('Votre compte est suspendu : action impossible.', code: 'COMPTE_SUSPENDU');
    }
    final allowed =
        user['kyc_passager'] == 'verifie' && user['kyc_conducteur'] == 'verifie' && user['vehicule_declare'] == true;
    if (!allowed) {
      throw const ForbiddenApiException(
        'Faites vérifier votre identité conducteur et déclarez votre véhicule pour publier.',
        code: 'KYC_CONDUCTEUR_REQUIS',
      );
    }
    return id;
  }

  Map<String, dynamic> _person(Map<String, dynamic> p, {bool driver = false}) => {
        'id': p['id'],
        'prenom': p['prenom'],
        'nom': p['nom'],
        'photo': null,
        'confiance': {
          'note_moyenne': p['note'],
          'nombre_notes': p['note'] == null ? 0 : 12,
          'fiabilite_pct': 100,
          'passager_verifie': true,
          'conducteur_verifie': driver,
        },
      };

  // ------------------------------------------------------------------ Trajets

  /// `POST /trajets/` (backend : PublicationSerializer). Le prix est fixé par Kovoit.
  Future<Map<String, dynamic>> publish(Map<String, dynamic> body) async {
    await _backend.wait();
    final driverId = await _driverId();
    final vehicle = _backend.vehicleJson(driverId)!;
    final points = (body['points'] as List).cast<Map<String, dynamic>>();
    final places = body['places'] as int;
    final departure = DateTime.parse(body['depart_le'] as String);
    final maxPlaces = (vehicle['nb_places'] as int) - 1;
    if (!departure.isAfter(_now)) {
      throw const BadRequestApiException("L'heure de départ doit être dans le futur.", code: 'DEPART_PASSE');
    }
    if (places < 1 || places > maxPlaces) {
      throw BadRequestApiException('Ce véhicule permet au plus $maxPlaces place(s) passager.', code: 'PLACES_INVALIDES');
    }
    if (points.isEmpty || points.length > 3) {
      throw const BadRequestApiException('Indiquez de 1 à 3 points de prise en charge.', code: 'DONNEES_INVALIDES');
    }

    final id = 'trajet-pub-${_backend.nextDriverTripId++}';
    final user = _backend.userJson(driverId);
    final trip = <String, dynamic>{
      'id': id,
      'conducteur_id': driverId,
      'conducteur': _person({'id': '$driverId', 'prenom': user['prenom'], 'nom': user['nom'], 'note': null}, driver: true),
      'vehicule': vehicle,
      'depart_lat': body['depart_lat'],
      'depart_lng': body['depart_lng'],
      'depart_libelle': body['depart_libelle'],
      'arrivee_lat': body['arrivee_lat'],
      'arrivee_lng': body['arrivee_lng'],
      'arrivee_libelle': body['arrivee_libelle'],
      'points': [
        for (final (index, p) in points.indexed)
          {'id': '$id-p${index + 1}', 'ordre': index + 1, 'lat': p['lat'], 'lng': p['lng'], 'libelle': p['libelle']},
      ],
      'depart_le': departure.toIso8601String(),
      'places_total': places,
      'places_restantes': places,
      'distance_km': FakeTrips.roadKm(
        (body['depart_lat'] as num).toDouble(),
        (body['depart_lng'] as num).toDouble(),
        (body['arrivee_lat'] as num).toDouble(),
        (body['arrivee_lng'] as num).toDouble(),
      ).toStringAsFixed(2),
      'prix_place': prixSimulation,
      'frais_service': FakeTrips.fraisService,
      'statut': 'publie',
      'position_le': null,
      'demandes': <Map<String, dynamic>>[],
    };
    _backend.driverTrips[id] = trip;

    // Démo : des passagers fictifs demandent une place au premier point de prise en charge.
    final firstPoint = (trip['points'] as List).first as Map<String, dynamic>;
    for (final passenger in _fakePassengers.take(places + 1)) {
      _requests(trip).add({
        'id': 'resa-${_backend.nextDriverRequestId++}',
        'passager': _person(passenger),
        'point': firstPoint,
        'arrivee_lat': body['arrivee_lat'],
        'arrivee_lng': body['arrivee_lng'],
        'arrivee_libelle': body['arrivee_libelle'],
        'statut': 'demandee',
        'prix': prixSimulation,
        'frais_service': FakeTrips.fraisService,
        'montant_total': prixSimulation + FakeTrips.fraisService,
        'cree_le': _now.toIso8601String(),
        'essais_code': 0,
      });
    }
    return _tripJson(trip);
  }

  /// `GET /trajets/mes-trajets/`.
  Future<List<Map<String, dynamic>>> myTrips() async {
    await _backend.wait();
    final driverId = await _driverId();
    final trips = _backend.driverTrips.values.where((t) => t['conducteur_id'] == driverId).toList()
      ..sort((a, b) => (a['depart_le'] as String).compareTo(b['depart_le'] as String));
    return [for (final t in trips) _tripJson(t)];
  }

  /// `GET /trajets/{id}/`.
  Future<Map<String, dynamic>> trip(String id) async {
    await _backend.wait();
    return _tripJson(await _ownedTrip(id));
  }

  /// `GET /trajets/{id}/reservations/` : demandes et réservations reçues (jamais de code).
  Future<List<Map<String, dynamic>>> requests(String tripId) async {
    await _backend.wait();
    final trip = await _ownedTrip(tripId);
    return [for (final r in _requests(trip)) _requestJson(trip, r)];
  }

  Future<Map<String, dynamic>> cancelTrip(String id) async {
    await _backend.wait();
    final trip = await _ownedTrip(id);
    final open = ['publie', 'complet'].contains(trip['statut']);
    if (!open || !_now.isBefore(DateTime.parse(trip['depart_le'] as String))) {
      throw const ConflictApiException('Ce trajet ne peut plus être annulé.', code: 'TRAJET_NON_ANNULABLE');
    }
    trip['statut'] = 'annule';
    for (final request in _requests(trip)) {
      if (['demandee', 'acceptee'].contains(request['statut'])) request['statut'] = 'annulee';
    }
    return _tripJson(trip);
  }

  Future<Map<String, dynamic>> finishTrip(String id) async {
    await _backend.wait();
    final trip = await _ownedTrip(id);
    if (!['publie', 'complet', 'en_cours'].contains(trip['statut'])) {
      throw const ConflictApiException('Ce trajet est déjà terminé ou annulé.', code: 'TRAJET_CLOS');
    }
    if (_requests(trip).any((r) => r['statut'] == 'acceptee')) {
      throw const ConflictApiException(
        'Saisissez le code de départ ou déclarez absents les passagers non montés.',
        code: 'PASSAGERS_EN_ATTENTE',
      );
    }
    for (final request in _requests(trip)) {
      if (request['statut'] == 'demandee') request['statut'] = 'refusee';
      if (request['statut'] == 'en_cours') {
        request['statut'] = 'terminee';
        _credit(trip, request); // démo : clôture immédiate (le vrai serveur attend la confirmation)
      }
    }
    trip['statut'] = 'termine';
    return _tripJson(trip);
  }

  // ------------------------------------------------------------------ Demandes

  Future<Map<String, dynamic>> accept(String requestId) async {
    await _backend.wait();
    final (trip, request) = await _ownedRequest(requestId);
    if (request['statut'] != 'demandee') {
      throw const ConflictApiException('Impossible de passer de « Acceptée » à « Acceptée ».', code: 'TRANSITION_INVALIDE');
    }
    if ((trip['places_restantes'] as int) < 1) {
      throw const ConflictApiException('Plus aucune place disponible sur ce trajet.', code: 'PLUS_DE_PLACE');
    }
    trip['places_restantes'] = (trip['places_restantes'] as int) - 1;
    if (trip['places_restantes'] == 0) trip['statut'] = 'complet';
    request['statut'] = 'acceptee';
    return _requestJson(trip, request);
  }

  Future<Map<String, dynamic>> refuse(String requestId) async {
    await _backend.wait();
    final (trip, request) = await _ownedRequest(requestId);
    if (request['statut'] != 'demandee') {
      throw const ConflictApiException('Cette demande a déjà été traitée.', code: 'TRANSITION_INVALIDE');
    }
    request['statut'] = 'refusee';
    return _requestJson(trip, request);
  }

  /// `POST /reservations/{id}/code-depart/`.
  Future<Map<String, dynamic>> submitCode(String requestId, String code) async {
    await _backend.wait();
    final (trip, request) = await _ownedRequest(requestId);
    if (request['statut'] != 'acceptee') {
      throw const ConflictApiException("Cette réservation n'attend pas de code.", code: 'CODE_NON_ATTENDU');
    }
    final attempts = request['essais_code'] as int;
    if (attempts >= maxCodeAttempts) {
      throw const ConflictApiException(
        "Trop d'essais : le code de départ est bloqué. Contactez le support.",
        code: 'CODE_DEPART_BLOQUE',
      );
    }
    // Le vrai serveur recalcule le code (HMAC) ; le conducteur n'y a jamais accès.
    if (code != DemoAccount.fakePassengerCode) {
      request['essais_code'] = attempts + 1;
      final left = maxCodeAttempts - attempts - 1;
      throw BadRequestApiException('Code de départ incorrect ($left essai(s) restant(s)).', code: 'CODE_DEPART_INVALIDE');
    }
    request['statut'] = 'en_cours';
    trip['statut'] = 'en_cours';
    return _requestJson(trip, request);
  }

  /// `POST /reservations/{id}/absent/` : après l'heure de départ + tolérance.
  Future<Map<String, dynamic>> declareAbsence(String requestId, {required double lat, required double lng}) async {
    await _backend.wait();
    final (trip, request) = await _ownedRequest(requestId);
    final from = DateTime.parse(trip['depart_le'] as String).add(const Duration(minutes: toleranceRetardMin));
    if (_now.isBefore(from)) {
      throw const ConflictApiException(
        'Attendez $toleranceRetardMin min après l\'heure de départ avant de déclarer une absence.',
        code: 'ABSENCE_PREMATUREE',
      );
    }
    if (request['statut'] != 'acceptee') {
      throw const ConflictApiException('Ce passager n’attend pas de prise en charge.', code: 'TRANSITION_INVALIDE');
    }
    request['statut'] = 'absent';
    _credit(trip, request);
    return _requestJson(trip, request);
  }

  // ------------------------------------------------------------------ Économies

  /// `GET /moi/economies/` : somme payée par les passagers, par trajet et cumul du mois.
  /// `POST /trajets/{id}/position/` : refusé sur un trajet terminé ou annulé (TRAJET_CLOS).
  Future<Map<String, dynamic>> updatePosition(String tripId, {required double lat, required double lng}) async {
    await _backend.wait();
    final trip = await _ownedTrip(tripId);
    if (['termine', 'annule'].contains(trip['statut'])) {
      throw const ConflictApiException('Le trajet est terminé.', code: 'TRAJET_CLOS');
    }
    trip
      ..['position_lat'] = lat
      ..['position_lng'] = lng
      ..['position_le'] = _now.toIso8601String();
    return _tripJson(trip);
  }

  Future<Map<String, dynamic>> savings() async {
    await _backend.wait();
    final driverId = await _backend.currentUserId();
    final lines = _backend.savings[driverId] ?? const <Map<String, dynamic>>[];
    final now = _now;
    final parTrajet = <String, Map<String, dynamic>>{};
    for (final line in lines) {
      final entry = parTrajet.putIfAbsent(line['trajet_id'] as String, () => {...line, 'montant': 0});
      entry['montant'] = (entry['montant'] as int) + (line['montant'] as int);
    }
    return {
      'mois_en_cours': lines
          .where((l) {
            final date = DateTime.parse(l['date'] as String);
            return date.year == now.year && date.month == now.month;
          })
          .fold<int>(0, (sum, l) => sum + (l['montant'] as int)),
      'total': lines.fold<int>(0, (sum, l) => sum + (l['montant'] as int)),
      'par_trajet': [
        for (final p in parTrajet.values)
          {
            'trajet_id': p['trajet_id'],
            'depart_le': p['depart_le'],
            'depart': p['depart'],
            'arrivee': p['arrivee'],
            'montant': p['montant'],
          },
      ],
    };
  }

  // ------------------------------------------------------------------ Outils

  /// Crédit du conducteur (clôture ou absence) : alimente `/moi/economies/`.
  void _credit(Map<String, dynamic> trip, Map<String, dynamic> request) {
    _backend.savings.putIfAbsent(trip['conducteur_id'] as int, () => []).add({
      'date': _now.toIso8601String(),
      'trajet_id': trip['id'],
      'depart_le': trip['depart_le'],
      'depart': trip['depart_libelle'],
      'arrivee': trip['arrivee_libelle'],
      'montant': request['prix'],
    });
  }

  List<Map<String, dynamic>> _requests(Map<String, dynamic> trip) =>
      (trip['demandes'] as List).cast<Map<String, dynamic>>();

  Future<Map<String, dynamic>> _ownedTrip(String id) async {
    final driverId = await _driverId();
    final trip = _backend.driverTrips[id];
    if (trip == null || trip['conducteur_id'] != driverId) throw const NotFoundApiException('Trajet introuvable.');
    return trip;
  }

  Future<(Map<String, dynamic>, Map<String, dynamic>)> _ownedRequest(String requestId) async {
    final driverId = await _driverId();
    for (final trip in _backend.driverTrips.values.where((t) => t['conducteur_id'] == driverId)) {
      for (final request in _requests(trip)) {
        if (request['id'] == requestId) return (trip, request);
      }
    }
    throw const NotFoundApiException('Réservation introuvable.');
  }

  /// TrajetConducteurSerializer : TrajetSerializer + `nb_demandes` + `position_le`.
  Map<String, dynamic> _tripJson(Map<String, dynamic> trip) => {
        for (final entry in trip.entries)
          if (entry.key != 'demandes' && entry.key != 'conducteur_id') entry.key: entry.value,
        'nb_demandes': _requests(trip).where((r) => r['statut'] == 'demandee').length,
      };

  /// ReservationConducteurSerializer : jamais de code de départ.
  Map<String, dynamic> _requestJson(Map<String, dynamic> trip, Map<String, dynamic> request) => {
        ...request,
        'trajet': trip['id'],
        'moyen_paiement': '',
        'complement_paye': 0,
        'annulation_tardive': false,
      };
}
