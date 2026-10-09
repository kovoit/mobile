import '../../../trip/domain/entities/geo_place.dart';
import '../../../vehicle/domain/entities/vehicle.dart';

/// Critères de recherche du passager (maquette « Rechercher un trajet »).
class SearchQuery {
  const SearchQuery({
    required this.depart,
    required this.arrivee,
    required this.dateTime,
    this.places = 1,
    this.vehicleType = VehicleType.voiture,
  });

  final GeoPlace depart;
  final GeoPlace arrivee;
  final DateTime dateTime;
  final int places;
  final VehicleType vehicleType;

  /// Sérialisation dans l'URL des résultats (lien partageable, survit à une reconstruction).
  Map<String, String> toQueryParameters() => {
        'dlib': depart.libelle,
        if (depart.quartier != null) 'dq': depart.quartier!,
        'dt': depart.type.apiValue,
        'dlat': depart.lat.toString(),
        'dlng': depart.lng.toString(),
        'alib': arrivee.libelle,
        if (arrivee.quartier != null) 'aq': arrivee.quartier!,
        'at': arrivee.type.apiValue,
        'alat': arrivee.lat.toString(),
        'alng': arrivee.lng.toString(),
        'quand': dateTime.toUtc().toIso8601String(),
        'places': '$places',
        'type': vehicleType.apiValue,
      };

  /// `null` si un paramètre manque ou est invalide (lien abîmé).
  static SearchQuery? fromQueryParameters(Map<String, String> params) {
    final dlat = double.tryParse(params['dlat'] ?? '');
    final dlng = double.tryParse(params['dlng'] ?? '');
    final alat = double.tryParse(params['alat'] ?? '');
    final alng = double.tryParse(params['alng'] ?? '');
    final when = DateTime.tryParse(params['quand'] ?? '');
    final dlib = params['dlib'];
    final alib = params['alib'];
    if ([dlat, dlng, alat, alng, when, dlib, alib].contains(null)) return null;
    return SearchQuery(
      depart: GeoPlace(
        libelle: dlib!,
        quartier: params['dq'],
        type: GeoPlaceType.fromApi(params['dt']),
        lat: dlat!,
        lng: dlng!,
      ),
      arrivee: GeoPlace(
        libelle: alib!,
        quartier: params['aq'],
        type: GeoPlaceType.fromApi(params['at']),
        lat: alat!,
        lng: alng!,
      ),
      dateTime: when!,
      places: (int.tryParse(params['places'] ?? '') ?? 1).clamp(1, 8),
      vehicleType: VehicleType.fromApi(params['type']),
    );
  }

  // Égalité de valeur : sert de clé au provider des résultats.
  @override
  bool operator ==(Object other) =>
      other is SearchQuery &&
      other.depart == depart &&
      other.arrivee == arrivee &&
      other.dateTime.isAtSameMomentAs(dateTime) &&
      other.places == places &&
      other.vehicleType == vehicleType;

  @override
  int get hashCode => Object.hash(depart, arrivee, dateTime.millisecondsSinceEpoch, places, vehicleType);
}

/// Itinéraire par la route du passager (OSRM côté backend), pour la carte des résultats.
class Itinerary {
  const Itinerary({required this.distanceKm, required this.durationMin, required this.points});

  final double distanceKm;
  final int durationMin;

  /// Polyligne (lat, lng).
  final List<(double lat, double lng)> points;
}
