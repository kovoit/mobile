import 'dart:math' as math;

/// Données et règles **serveur** simulées pour la recherche (`Env.useMockApi`).
/// Le JSON suit exactement le backend (TrajetSerializer, ResultatRechercheSerializer,
/// LieuConnuSerializer) ; il n'est jamais utilisé avec le vrai backend.
/// Les distances sont à vol d'oiseau, suffisant pour une démo.
abstract final class FakeTrips {
  // Paramètres administrateur (valeurs de départ du PRD).
  static const double rayonDepartKm = 1.5;
  static const double rayonArriveeKm = 1.5;
  static const int fenetreHoraireMin = 15;
  static const int fraisService = 0; // paramètre `frais_service` : 0 F pendant le pilote
  static const int rechargeMin = 500; // paramètre `recharge_min`

  /// Lieux connus de Lomé (mêmes données que la migration backend lieux/0002).
  static const List<Map<String, dynamic>> lieux = [
    {'id': 'lieu-1', 'libelle': 'Carrefour Franciscain', 'quartier': 'Adidogomé', 'type': 'carrefour', 'lat': 6.1660, 'lng': 1.1650},
    {'id': 'lieu-2', 'libelle': 'Carrefour Avedji', 'quartier': 'Avedji', 'type': 'carrefour', 'lat': 6.1690, 'lng': 1.1840},
    {'id': 'lieu-3', 'libelle': 'Carrefour Totsi', 'quartier': 'Totsi', 'type': 'carrefour', 'lat': 6.1780, 'lng': 1.1980},
    {'id': 'lieu-4', 'libelle': 'Université de Lomé · Entrée sud', 'quartier': 'Tokoin', 'type': 'repere', 'lat': 6.1680, 'lng': 1.2140},
    {'id': 'lieu-5', 'libelle': 'Grand Marché', 'quartier': 'Assigamé', 'type': 'repere', 'lat': 6.1300, 'lng': 1.2230},
    {'id': 'lieu-6', 'libelle': 'Carrefour Déckon', 'quartier': 'Centre-ville', 'type': 'carrefour', 'lat': 6.1310, 'lng': 1.2180},
    {'id': 'lieu-7', 'libelle': 'CHU Sylvanus Olympio', 'quartier': 'Tokoin', 'type': 'repere', 'lat': 6.1350, 'lng': 1.2160},
    {'id': 'lieu-8', 'libelle': 'Agoè-Zongo', 'quartier': 'Agoè', 'type': 'carrefour', 'lat': 6.2200, 'lng': 1.2050},
    {'id': 'lieu-9', 'libelle': 'Agoè Assiyéyé', 'quartier': 'Agoè', 'type': 'quartier', 'lat': 6.2290, 'lng': 1.2120},
    {'id': 'lieu-10', 'libelle': 'Bè Kpota', 'quartier': 'Bè', 'type': 'quartier', 'lat': 6.1420, 'lng': 1.2420},
    {'id': 'lieu-11', 'libelle': 'Port autonome', 'quartier': 'Zone portuaire', 'type': 'repere', 'lat': 6.1360, 'lng': 1.2850},
    {'id': 'lieu-12', 'libelle': 'Baguida centre', 'quartier': 'Baguida', 'type': 'quartier', 'lat': 6.1530, 'lng': 1.3200},
    {'id': 'lieu-13', 'libelle': 'Hédzranawoé', 'quartier': 'Hédzranawoé', 'type': 'quartier', 'lat': 6.1590, 'lng': 1.2420},
    {'id': 'lieu-14', 'libelle': 'Stade de Kégué', 'quartier': 'Kégué', 'type': 'repere', 'lat': 6.1810, 'lng': 1.2490},
    {'id': 'lieu-15', 'libelle': 'Tokoin Hôpital', 'quartier': 'Tokoin', 'type': 'carrefour', 'lat': 6.1450, 'lng': 1.2140},
  ];

  static Map<String, dynamic> _lieu(int n) => lieux[n - 1];

  /// Trajets publiés chaque jour (heure de Lomé = UTC).
  static final List<_TripTemplate> _templates = [
    _TripTemplate(
      driver: _driver(101, 'Koffi', 'Mensah', 4.9, 98, 128),
      vehicle: _vehicle(101, 'voiture', 'Toyota', 'Yaris', 'Gris', 'TG 4827 AU'),
      departId: 1, arriveeId: 4, pickupIds: [1, 2, 3], hour: 7, minute: 30, places: 2, price: 300,
    ),
    _TripTemplate(
      driver: _driver(102, 'Akossiwa', 'Amégan', 4.8, 95, 64),
      vehicle: _vehicle(102, 'voiture', 'Kia', 'Picanto', 'Rouge', 'TG 1290 BC'),
      departId: 2, arriveeId: 4, pickupIds: [2, 1, 3], hour: 7, minute: 40, places: 3, price: 300,
    ),
    _TripTemplate(
      driver: _driver(103, 'Kossi', 'Akakpo', 4.7, 92, 41),
      vehicle: _vehicle(103, 'voiture', 'Hyundai', 'i10', 'Blanc', 'TG 7731 AF'),
      departId: 1, arriveeId: 4, pickupIds: [1, 3], hour: 7, minute: 45, places: 1, price: 300,
    ),
    _TripTemplate(
      driver: _driver(104, 'Yawo', 'Dzidzo', 4.6, 97, 210),
      vehicle: _vehicle(104, 'moto', 'Haojue', 'HJ125', 'Noire', 'TG 2210 AK'),
      departId: 1, arriveeId: 4, pickupIds: [1, 2], hour: 7, minute: 35, places: 1, price: 300,
    ),
    _TripTemplate(
      driver: _driver(105, 'Ama', 'Kpodar', 4.9, 99, 87),
      vehicle: _vehicle(105, 'voiture', 'Toyota', 'Corolla', 'Bleue', 'TG 5512 BA'),
      departId: 8, arriveeId: 5, pickupIds: [8, 9], hour: 7, minute: 15, places: 3, price: 300,
    ),
    _TripTemplate(
      driver: _driver(106, 'Edem', 'Lawson', 4.5, 90, 23),
      vehicle: _vehicle(106, 'voiture', 'Suzuki', 'Alto', 'Grise', 'TG 3398 AH'),
      departId: 12, arriveeId: 6, pickupIds: [12, 13], hour: 17, minute: 30, places: 2, price: 300,
    ),
    _TripTemplate(
      driver: _driver(107, 'Sena', 'Ahiadzro', 4.8, 96, 152),
      vehicle: _vehicle(107, 'moto', 'Sanya', 'SY125', 'Rouge', 'TG 8840 AM'),
      departId: 10, arriveeId: 11, pickupIds: [10], hour: 8, minute: 0, places: 1, price: 300,
    ),
    _TripTemplate(
      driver: _driver(101, 'Koffi', 'Mensah', 4.9, 98, 128),
      vehicle: _vehicle(101, 'voiture', 'Toyota', 'Yaris', 'Gris', 'TG 4827 AU'),
      departId: 4, arriveeId: 1, pickupIds: [4, 3], hour: 17, minute: 30, places: 3, price: 300,
    ),
  ];

  /// Tracés « par la route » dessinés à la main (`source: routage`), par indice de modèle.
  /// Les autres modèles reçoivent des segments droits (`estimation`), sauf ceux de
  /// [_tripsWithoutTrace] (trajets publiés avant l'enregistrement des tracés : `trace: null`).
  static const Map<int, List<List<double>>> _routedTraces = {
    // Koffi : Carrefour Franciscain → Avedji → Totsi → Université de Lomé.
    0: [
      [6.16600, 1.16500], [6.16650, 1.17000], [6.16720, 1.17550], [6.16810, 1.18000], [6.16900, 1.18400],
      [6.17150, 1.18800], [6.17420, 1.19250], [6.17800, 1.19800], [6.17640, 1.20300], [6.17300, 1.20750],
      [6.17020, 1.21100], [6.16800, 1.21400],
    ],
    // Yawo (moto) : Carrefour Franciscain → Avedji → Université de Lomé.
    3: [
      [6.16600, 1.16500], [6.16650, 1.17000], [6.16720, 1.17550], [6.16810, 1.18000], [6.16900, 1.18400],
      [6.16950, 1.19000], [6.16920, 1.19700], [6.16880, 1.20400], [6.16840, 1.20900], [6.16800, 1.21400],
    ],
  };
  static const Set<int> _tripsWithoutTrace = {6};

  /// Bloc `trace` du détail (TrajetDetailSerializer) : départ → carrefours (ordre) → arrivée.
  static Map<String, dynamic>? _traceJson(int index, _TripTemplate t) {
    if (_tripsWithoutTrace.contains(index)) return null;
    final routed = _routedTraces[index];
    if (routed != null) return {'source': 'routage', 'points': routed};
    List<double> pair(int lieuId) => [_lieu(lieuId)['lat'] as double, _lieu(lieuId)['lng'] as double];
    return {
      'source': 'estimation',
      'points': [pair(t.departId), for (final id in t.pickupIds) pair(id), pair(t.arriveeId)],
    };
  }

  /// Profil public (PersonneSerializer) : jamais d'email ni de téléphone.
  static Map<String, dynamic> _driver(int id, String prenom, String nom, double note, int fiabilite, int notes) => {
        'id': 'u$id',
        'prenom': prenom,
        'nom': nom,
        'photo': null,
        'confiance': {
          'note_moyenne': note,
          'nombre_notes': notes,
          'fiabilite_pct': fiabilite,
          'passager_verifie': true,
          'conducteur_verifie': true,
        },
      };

  static Map<String, dynamic> _vehicle(int id, String type, String marque, String modele, String couleur, String plaque) => {
        'id': 'v$id',
        'type_vehicule': type,
        'marque': marque,
        'modele': modele,
        'couleur': couleur,
        'immatriculation': plaque,
        'nb_places': type == 'moto' ? 2 : 5,
        'photo': null,
      };

  // ------------------------------------------------------------------ Requêtes

  /// `GET /lieux/?q=` : 2 caractères minimum, sans accents, 20 au plus.
  static List<Map<String, dynamic>> searchPlaces(String? query) {
    final q = normalize(query ?? '');
    if (q.length < 2) return lieux.take(20).toList();
    return lieux.where((l) => normalize('${l['libelle']} ${l['quartier']}').contains(q)).take(20).toList();
  }

  /// `GET /trajets/recherche/` : liste de `{trajet, point_propose, distance_marche_km,
  /// ecart_minutes}`, triée par heure de départ puis distance de marche (comme le serveur).
  static List<Map<String, dynamic>> search({
    required double departLat,
    required double departLng,
    required double arriveeLat,
    required double arriveeLng,
    required DateTime dateHeure,
  }) {
    final requested = dateHeure.toUtc();
    final results = <Map<String, dynamic>>[];

    for (final (index, template) in _templates.indexed) {
      final departure = DateTime.utc(requested.year, requested.month, requested.day, template.hour, template.minute);
      final gapMin = departure.difference(requested).inMinutes.abs();
      if (gapMin > fenetreHoraireMin || template.places < 1) continue;

      final arrivee = _lieu(template.arriveeId);
      if (_km(arriveeLat, arriveeLng, arrivee['lat'] as double, arrivee['lng'] as double) > rayonArriveeKm) continue;

      final trip = _tripJson(index, template, departure);
      final points = (trip['points'] as List).cast<Map<String, dynamic>>();
      final nearest = points
          .map((p) => (point: p, km: _km(departLat, departLng, p['lat'] as double, p['lng'] as double)))
          .reduce((a, b) => a.km <= b.km ? a : b);
      if (nearest.km > rayonDepartKm) continue;

      results.add({
        'trajet': trip,
        'point_propose': nearest.point,
        'distance_marche_km': double.parse(nearest.km.toStringAsFixed(2)),
        'ecart_minutes': gapMin,
      });
    }

    results.sort((a, b) {
      final byTime = ((a['trajet'] as Map)['depart_le'] as String).compareTo((b['trajet'] as Map)['depart_le'] as String);
      return byTime != 0 ? byTime : (a['distance_marche_km'] as double).compareTo(b['distance_marche_km'] as double);
    });
    return results;
  }

  /// `GET /trajets/{id}/` avec l'aperçu du paiement et le tracé, pour un passager qui dispose de
  /// [soldeDisponible] F CFA. L'identifiant encode la date et le modèle : `trajet-AAAAMMJJ-II`.
  static Map<String, dynamic>? tripById(String id, {int soldeDisponible = 0}) {
    final match = RegExp(r'^trajet-(\d{8})-(\d{2})$').firstMatch(id);
    if (match == null) return null;
    final index = int.parse(match.group(2)!);
    final date = DateTime.tryParse(match.group(1)!);
    if (date == null || index >= _templates.length) return null;
    final template = _templates[index];
    final departure = DateTime.utc(date.year, date.month, date.day, template.hour, template.minute);
    final montant = template.price + fraisService;
    final disponible = math.max(soldeDisponible, 0);
    return _tripJson(index, template, departure)
      ..['prix_passager'] = template.price
      ..['trace'] = _traceJson(index, template)
      ..['paiement'] = {
        'montant_total': montant,
        'solde_disponible': disponible,
        'complement_a_payer': math.max(montant - disponible, 0),
        'recharge_suggeree': montant > disponible ? math.max(montant - disponible, rechargeMin) : 0,
        'moyens_paiement': [
          {'code': 'flooz', 'libelle': 'Flooz (Moov Africa)'},
          {'code': 'mixx', 'libelle': 'Mixx (Togocom)'},
        ],
      };
  }

  // ------------------------------------------------------------------ Outils

  static Map<String, dynamic> _tripJson(int index, _TripTemplate t, DateTime departure) {
    final date = '${departure.year}${departure.month.toString().padLeft(2, '0')}${departure.day.toString().padLeft(2, '0')}';
    final depart = _lieu(t.departId);
    final arrivee = _lieu(t.arriveeId);
    return {
      'id': 'trajet-$date-${index.toString().padLeft(2, '0')}',
      'conducteur': t.driver,
      'vehicule': t.vehicle,
      'depart_lat': depart['lat'],
      'depart_lng': depart['lng'],
      'depart_libelle': depart['libelle'],
      'arrivee_lat': arrivee['lat'],
      'arrivee_lng': arrivee['lng'],
      'arrivee_libelle': arrivee['libelle'],
      'points': [
        for (final (ordre, lieuId) in t.pickupIds.indexed)
          {
            'id': 'point-$index-$lieuId',
            'ordre': ordre + 1,
            'lat': _lieu(lieuId)['lat'],
            'lng': _lieu(lieuId)['lng'],
            'libelle': _lieu(lieuId)['libelle'],
          },
      ],
      'depart_le': departure.toIso8601String(),
      'places_total': t.places,
      'places_restantes': t.places,
      'distance_km': roadKm(depart['lat'] as double, depart['lng'] as double, arrivee['lat'] as double, arrivee['lng'] as double)
          .toStringAsFixed(2),
      'prix_place': t.price,
      'frais_service': fraisService,
      'statut': 'publie',
    };
  }

  static String normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp('[éèêë]'), 'e')
      .replaceAll(RegExp('[àâä]'), 'a')
      .replaceAll(RegExp('[ïî]'), 'i')
      .replaceAll(RegExp('[ôö]'), 'o')
      .replaceAll(RegExp('[ùûü]'), 'u')
      .trim();

  /// Distance « par la route » simulée (vol d'oiseau × 1,3), en km.
  static double roadKm(double lat1, double lng1, double lat2, double lng2) => _km(lat1, lng1, lat2, lng2) * 1.3;

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
}
