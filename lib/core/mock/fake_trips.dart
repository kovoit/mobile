import 'dart:math' as math;

/// Données et règles **serveur** simulées pour la recherche (`Env.useMockApi`).
/// Ce fichier reproduit ce que fera le backend (docs/api/trips.md) : il n'est jamais utilisé
/// avec le vrai backend. Les distances sont à vol d'oiseau, suffisant pour une démo.
abstract final class FakeTrips {
  // Paramètres administrateur (valeurs de départ du PRD §10).
  static const double rayonDepartKm = 1.5;
  static const double rayonArriveeKm = 1.5;
  static const int fenetreHoraireMin = 15;

  /// Lieux connus de Lomé (coordonnées approximatives, démo uniquement).
  static const List<Map<String, dynamic>> lieux = [
    {'id': 1, 'libelle': 'Carrefour Franciscain', 'quartier': 'Adidogomé', 'type': 'carrefour', 'lat': 6.1660, 'lng': 1.1650},
    {'id': 2, 'libelle': 'Carrefour Avedji', 'quartier': 'Avedji', 'type': 'carrefour', 'lat': 6.1690, 'lng': 1.1840},
    {'id': 3, 'libelle': 'Carrefour Totsi', 'quartier': 'Totsi', 'type': 'carrefour', 'lat': 6.1780, 'lng': 1.1980},
    {'id': 4, 'libelle': 'Université de Lomé · Entrée sud', 'quartier': 'Tokoin', 'type': 'repere', 'lat': 6.1680, 'lng': 1.2140},
    {'id': 5, 'libelle': 'Grand Marché', 'quartier': 'Assigamé', 'type': 'repere', 'lat': 6.1300, 'lng': 1.2230},
    {'id': 6, 'libelle': 'Carrefour Déckon', 'quartier': 'Centre-ville', 'type': 'carrefour', 'lat': 6.1310, 'lng': 1.2180},
    {'id': 7, 'libelle': 'CHU Sylvanus Olympio', 'quartier': 'Tokoin', 'type': 'repere', 'lat': 6.1350, 'lng': 1.2160},
    {'id': 8, 'libelle': 'Agoè-Zongo', 'quartier': 'Agoè', 'type': 'carrefour', 'lat': 6.2200, 'lng': 1.2050},
    {'id': 9, 'libelle': 'Agoè Assiyéyé', 'quartier': 'Agoè', 'type': 'quartier', 'lat': 6.2290, 'lng': 1.2120},
    {'id': 10, 'libelle': 'Bè Kpota', 'quartier': 'Bè', 'type': 'quartier', 'lat': 6.1420, 'lng': 1.2420},
    {'id': 11, 'libelle': 'Port autonome', 'quartier': 'Zone portuaire', 'type': 'repere', 'lat': 6.1360, 'lng': 1.2850},
    {'id': 12, 'libelle': 'Baguida centre', 'quartier': 'Baguida', 'type': 'quartier', 'lat': 6.1530, 'lng': 1.3200},
    {'id': 13, 'libelle': 'Hédzranawoé', 'quartier': 'Hédzranawoé', 'type': 'quartier', 'lat': 6.1590, 'lng': 1.2420},
    {'id': 14, 'libelle': 'Stade de Kégué', 'quartier': 'Kégué', 'type': 'repere', 'lat': 6.1810, 'lng': 1.2490},
    {'id': 15, 'libelle': 'Tokoin Hôpital', 'quartier': 'Tokoin', 'type': 'carrefour', 'lat': 6.1450, 'lng': 1.2140},
  ];

  static Map<String, dynamic> _lieu(int id) => lieux.firstWhere((l) => l['id'] == id);

  /// Trajets publiés chaque jour (heure de Lomé = UTC).
  static final List<_TripTemplate> _templates = [
    _TripTemplate(
      driver: _driver(101, 'Koffi', 'Mensah', 4.9, 98, 128),
      vehicle: _vehicle('voiture', 'Toyota', 'Yaris', 'Gris', 'TG 4827 AU'),
      departId: 1, arriveeId: 4, pickupIds: [1, 2, 3], hour: 7, minute: 30, places: 2, price: 300, durationMin: 25,
    ),
    _TripTemplate(
      driver: _driver(102, 'Akossiwa', 'Amégan', 4.8, 95, 64),
      vehicle: _vehicle('voiture', 'Kia', 'Picanto', 'Rouge', 'TG 1290 BC'),
      departId: 2, arriveeId: 4, pickupIds: [2, 1, 3], hour: 7, minute: 40, places: 3, price: 300, durationMin: 20,
    ),
    _TripTemplate(
      driver: _driver(103, 'Kossi', 'Akakpo', 4.7, 92, 41),
      vehicle: _vehicle('voiture', 'Hyundai', 'i10', 'Blanc', 'TG 7731 AF'),
      departId: 1, arriveeId: 4, pickupIds: [1, 3], hour: 7, minute: 45, places: 1, price: 300, durationMin: 25,
    ),
    _TripTemplate(
      driver: _driver(104, 'Yawo', 'Dzidzo', 4.6, 97, 210),
      vehicle: _vehicle('moto', 'Haojue', 'HJ125', 'Noire', 'TG 2210 AK'),
      departId: 1, arriveeId: 4, pickupIds: [1, 2], hour: 7, minute: 35, places: 1, price: 200, durationMin: 18,
    ),
    _TripTemplate(
      driver: _driver(105, 'Ama', 'Kpodar', 4.9, 99, 87),
      vehicle: _vehicle('voiture', 'Toyota', 'Corolla', 'Bleue', 'TG 5512 BA'),
      departId: 8, arriveeId: 5, pickupIds: [8, 9], hour: 7, minute: 15, places: 3, price: 500, durationMin: 35,
    ),
    _TripTemplate(
      driver: _driver(106, 'Edem', 'Lawson', 4.5, 90, 23),
      vehicle: _vehicle('voiture', 'Suzuki', 'Alto', 'Grise', 'TG 3398 AH'),
      departId: 12, arriveeId: 6, pickupIds: [12, 13], hour: 17, minute: 30, places: 2, price: 500, durationMin: 30,
    ),
    _TripTemplate(
      driver: _driver(107, 'Sena', 'Ahiadzro', 4.8, 96, 152),
      vehicle: _vehicle('moto', 'Sanya', 'SY125', 'Rouge', 'TG 8840 AM'),
      departId: 10, arriveeId: 11, pickupIds: [10], hour: 8, minute: 0, places: 1, price: 200, durationMin: 12,
    ),
    _TripTemplate(
      driver: _driver(101, 'Koffi', 'Mensah', 4.9, 98, 128),
      vehicle: _vehicle('voiture', 'Toyota', 'Yaris', 'Gris', 'TG 4827 AU'),
      departId: 4, arriveeId: 1, pickupIds: [4, 3], hour: 17, minute: 30, places: 3, price: 300, durationMin: 30,
    ),
  ];

  static Map<String, dynamic> _driver(int id, String prenom, String nom, double note, int fiabilite, int nbTrajets) => {
        'id': id,
        'prenom': prenom,
        'nom': nom,
        'photo': null,
        'verifie': true,
        'note': note,
        'fiabilite': fiabilite,
        'nb_trajets': nbTrajets,
      };

  static Map<String, dynamic> _vehicle(String type, String marque, String modele, String couleur, String plaque) => {
        'type': type,
        'marque': marque,
        'modele': modele,
        'couleur': couleur,
        'immatriculation': plaque,
        'photo': null,
      };

  // ------------------------------------------------------------------ Requêtes

  static List<Map<String, dynamic>> searchPlaces(String? query) {
    final q = _normalize(query ?? '');
    if (q.length < 2) return lieux.take(8).toList();
    return lieux
        .where((l) => _normalize('${l['libelle']} ${l['quartier']}').contains(q))
        .take(20)
        .toList();
  }

  /// `GET /trajets/recherche/` : correspondance, tri et itinéraire, comme le ferait le serveur.
  static Map<String, dynamic> search({
    required double departLat,
    required double departLng,
    required double arriveeLat,
    required double arriveeLng,
    required DateTime dateHeure,
    required int places,
    required String typeVehicule,
  }) {
    final requested = dateHeure.toUtc();
    final matches = <({Map<String, dynamic> trip, int gapMin, double walkKm})>[];

    for (final (index, template) in _templates.indexed) {
      if (template.vehicle['type'] != typeVehicule || template.places < places) continue;
      final departure = DateTime.utc(requested.year, requested.month, requested.day, template.hour, template.minute);
      final gapMin = departure.difference(requested).inMinutes.abs();
      if (gapMin > fenetreHoraireMin) continue;

      final arrivee = _lieu(template.arriveeId);
      if (_km(arriveeLat, arriveeLng, arrivee['lat'] as double, arrivee['lng'] as double) > rayonArriveeKm) continue;

      final pickups = [for (final id in template.pickupIds) _lieu(id)];
      final nearest = pickups
          .map((p) => (point: p, km: _km(departLat, departLng, p['lat'] as double, p['lng'] as double)))
          .reduce((a, b) => a.km <= b.km ? a : b);
      if (nearest.km > rayonDepartKm) continue;

      final trip = _tripJson(index, template, departure, places: places)
        ..['point_correspondant_id'] = _pickupId(index, nearest.point['id'] as int)
        ..['distance_marche_km'] = double.parse(nearest.km.toStringAsFixed(1));
      matches.add((trip: trip, gapMin: gapMin, walkKm: nearest.km));
    }

    matches.sort((a, b) {
      final byTime = (a.trip['depart_le'] as String).compareTo(b.trip['depart_le'] as String);
      return byTime != 0 ? byTime : a.walkKm.compareTo(b.walkKm);
    });

    final roadKm = _km(departLat, departLng, arriveeLat, arriveeLng) * 1.3;
    return {
      'itineraire': {
        'distance_km': double.parse(roadKm.toStringAsFixed(1)),
        'duree_min': math.max(5, (roadKm / 20 * 60).round()),
        'points': [
          [departLat, departLng],
          [departLat, (departLng + arriveeLng) / 2],
          [arriveeLat, (departLng + arriveeLng) / 2],
          [arriveeLat, arriveeLng],
        ],
      },
      'resultats': [for (final m in matches) m.trip],
    };
  }

  /// `GET /trajets/{id}/` ; l'identifiant encode la date et le modèle (AAAAMMJJ + 2 chiffres).
  static Map<String, dynamic>? tripById(int id, {int places = 1}) {
    final index = id % 100;
    final datePart = id ~/ 100;
    if (index >= _templates.length) return null;
    final date = DateTime.tryParse(datePart.toString());
    if (date == null) return null;
    final template = _templates[index];
    final departure = DateTime.utc(date.year, date.month, date.day, template.hour, template.minute);
    return _tripJson(index, template, departure, places: places)..['point_correspondant_id'] = _pickupId(index, template.pickupIds.first);
  }

  // ------------------------------------------------------------------ Outils

  static Map<String, dynamic> _tripJson(int index, _TripTemplate t, DateTime departure, {required int places}) {
    const fraisService = 0; // paramètre `frais_service` : 0 F pendant le pilote (D2)
    final date = '${departure.year}${departure.month.toString().padLeft(2, '0')}${departure.day.toString().padLeft(2, '0')}';
    return {
      'id': int.parse('$date${index.toString().padLeft(2, '0')}'),
      'conducteur': t.driver,
      'vehicule': t.vehicle,
      'depart': _place(_lieu(t.departId)),
      'arrivee': _place(_lieu(t.arriveeId)),
      'points_prise_en_charge': [
        for (final (ordre, id) in t.pickupIds.indexed)
          {..._place(_lieu(id)), 'id': _pickupId(index, id), 'ordre': ordre + 1},
      ],
      'depart_le': departure.toIso8601String(),
      'arrivee_estimee_le': departure.add(Duration(minutes: t.durationMin)).toIso8601String(),
      'places_restantes': t.places,
      'prix_place': t.price,
      'frais_service': fraisService,
      'prix_total': (t.price + fraisService) * places,
    };
  }

  static Map<String, dynamic> _place(Map<String, dynamic> lieu) => {
        'libelle': lieu['libelle'],
        'quartier': lieu['quartier'],
        'type': lieu['type'],
        'lat': lieu['lat'],
        'lng': lieu['lng'],
      };

  static int _pickupId(int templateIndex, int lieuId) => templateIndex * 100 + lieuId;

  static String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp('[éèêë]'), 'e')
      .replaceAll(RegExp('[àâä]'), 'a')
      .replaceAll(RegExp('[ïî]'), 'i')
      .replaceAll(RegExp('[ôö]'), 'o')
      .replaceAll(RegExp('[ùûü]'), 'u')
      .trim();

  /// Distance à vol d'oiseau (Haversine), en km.
  static double _km(double lat1, double lng1, double lat2, double lng2) {
    const earthRadiusKm = 6371.0;
    double rad(double deg) => deg * math.pi / 180;
    final dLat = rad(lat2 - lat1);
    final dLng = rad(lng2 - lng1);
    final a = math.pow(math.sin(dLat / 2), 2) + math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.pow(math.sin(dLng / 2), 2);
    return earthRadiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }
}

class _TripTemplate {
  const _TripTemplate({
    required this.driver,
    required this.vehicle,
    required this.departId,
    required this.arriveeId,
    required this.pickupIds,
    required this.hour,
    required this.minute,
    required this.places,
    required this.price,
    required this.durationMin,
  });

  final Map<String, dynamic> driver;
  final Map<String, dynamic> vehicle;
  final int departId;
  final int arriveeId;
  final List<int> pickupIds;
  final int hour;
  final int minute;
  final int places;
  final int price;
  final int durationMin;
}
