import '../../../trip/domain/entities/geo_place.dart';
import '../../../vehicle/domain/entities/vehicle.dart';

/// Critères de recherche du passager (maquette « Rechercher un trajet »).
/// Une réservation = une place (D-13) ; filtre Moto / Voiture (D-12), appliqué par le backend.
class SearchQuery {
  const SearchQuery({required this.depart, required this.arrivee, required this.dateTime, this.vehicleType});

  final GeoPlace depart;
  final GeoPlace arrivee;
  final DateTime dateTime;

  /// Type de véhicule recherché ; `null` = tous les types.
  final VehicleType? vehicleType;

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
        if (vehicleType != null) 'type': vehicleType!.apiValue,
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
      vehicleType: _vehicleTypeFrom(params['type']),
    );
  }

  /// Valeur absente ou inconnue → tous les types (pas de repli sur « voiture » comme [VehicleType.fromApi]).
  static VehicleType? _vehicleTypeFrom(String? value) {
    for (final type in VehicleType.values) {
      if (type.apiValue == value) return type;
    }
    return null;
  }

  // Égalité de valeur : sert de clé au provider des résultats.
  @override
  bool operator ==(Object other) =>
      other is SearchQuery &&
      other.depart == depart &&
      other.arrivee == arrivee &&
      other.dateTime.isAtSameMomentAs(dateTime) &&
      other.vehicleType == vehicleType;

  @override
  int get hashCode => Object.hash(depart, arrivee, dateTime.millisecondsSinceEpoch, vehicleType);
}
