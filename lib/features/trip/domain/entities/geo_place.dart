enum GeoPlaceType {
  carrefour('carrefour'),
  quartier('quartier'),
  repere('repere'),
  pointCarte('point_carte');

  const GeoPlaceType(this.apiValue);

  final String apiValue;

  static GeoPlaceType fromApi(String? value) =>
      values.firstWhere((t) => t.apiValue == value, orElse: () => GeoPlaceType.repere);
}

/// Lieu géolocalisé : coordonnées GPS + libellé (quartier, repère connu), spéc. §Trajets.
class GeoPlace {
  const GeoPlace({
    required this.libelle,
    required this.lat,
    required this.lng,
    this.id,
    this.quartier,
    this.type = GeoPlaceType.repere,
  });

  /// `null` pour un point choisi sur la carte.
  final int? id;
  final String libelle;
  final String? quartier;
  final double lat;
  final double lng;
  final GeoPlaceType type;

  /// Libellé complet des champs de la maquette : un carrefour est précisé par son quartier
  /// (« Carrefour Franciscain, Adidogomé »), un repère se suffit (« Université de Lomé · Entrée sud »).
  String get fullLabel {
    final hasArea = quartier != null && quartier!.isNotEmpty && !libelle.contains(quartier!);
    return hasArea && type == GeoPlaceType.carrefour ? '$libelle, $quartier' : libelle;
  }

  /// Libellé court pour les trajets « Adidogomé → Université de Lomé » (maquette « Conducteurs disponibles ») :
  /// un carrefour ou un quartier se résume à son quartier, un repère à son nom (« Université de Lomé · Entrée sud »
  /// devient « Université de Lomé »).
  String get displayName {
    final hasArea = quartier != null && quartier!.isNotEmpty;
    if (hasArea && (type == GeoPlaceType.carrefour || type == GeoPlaceType.quartier)) return quartier!;
    return libelle.split(' · ').first;
  }

  @override
  bool operator ==(Object other) =>
      other is GeoPlace && other.id == id && other.libelle == libelle && other.lat == lat && other.lng == lng;

  @override
  int get hashCode => Object.hash(id, libelle, lat, lng);
}
