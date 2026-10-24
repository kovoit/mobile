enum VehicleType {
  moto('moto'),
  voiture('voiture');

  const VehicleType(this.apiValue);

  final String apiValue;

  static VehicleType fromApi(String? value) =>
      values.firstWhere((t) => t.apiValue == value, orElse: () => VehicleType.voiture);
}

/// Véhicule du conducteur. [nbPlaces] = places totales, conducteur compris.
/// Les places proposées à la publication (≤ nbPlaces − 1) sont contrôlées par le backend.
class Vehicle {
  const Vehicle({
    required this.type,
    required this.marque,
    required this.modele,
    required this.couleur,
    required this.immatriculation,
    required this.nbPlaces,
    this.id,
    this.consommationL100km,
  });

  /// UUID côté backend ; `null` tant que le véhicule n'est pas déclaré.
  final String? id;
  final VehicleType type;
  final String marque;
  final String modele;
  final String couleur;
  final String immatriculation;
  final int nbPlaces;

  /// Consommation déclarée (L/100 km), utilisée pour le prix ; null = référence du type.
  final double? consommationL100km;

  /// « Toyota Yaris »
  String get label => '$marque $modele'.trim();
}
