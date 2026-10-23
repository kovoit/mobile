/// Détail du prix d'un trajet, calculé et figé par le backend (apps/tarification/calcul.py).
///
/// L'application n'effectue aucun calcul de prix : elle affiche ces montants. Seule la
/// participation du conducteur selon le nombre de places réellement payées est dérivée ici,
/// par une soustraction des montants renvoyés (coût total − net par place × places payées).
class PriceBreakdown {
  const PriceBreakdown({
    required this.formuleVersion,
    required this.typeVehicule,
    required this.distanceKm,
    required this.dureeMin,
    required this.estimatedRoute,
    required this.passagersPrevus,
    required this.consommationL100km,
    required this.vehicleConsumption,
    required this.carburantLitres,
    required this.prixCarburantLitre,
    required this.coutCarburant,
    required this.coutTemps,
    required this.coutEntretien,
    required this.coutTotal,
    required this.partConducteur,
    required this.contributionPassagers,
    required this.prixPlace,
    required this.commissionPlace,
    required this.netConducteurPlace,
    required this.totalPayePassagers,
    required this.commissionKovoit,
    required this.netConducteur,
    required this.tauxCommissionPct,
  });

  final String formuleVersion;
  final String typeVehicule;
  final double distanceKm;
  final int dureeMin;

  /// Itinéraire indisponible au calcul : distance et durée estimées par le backend.
  final bool estimatedRoute;

  /// Base du partage des frais : les places proposées (pas des passagers confirmés).
  final int passagersPrevus;
  final double consommationL100km;

  /// Consommation déclarée pour ce véhicule (sinon : référence du type).
  final bool vehicleConsumption;
  final double carburantLitres;
  final double prixCarburantLitre;
  final double coutCarburant;
  final double coutTemps;
  final double coutEntretien;
  final double coutTotal;
  final double partConducteur;
  final double contributionPassagers;
  final int prixPlace;
  final int commissionPlace;
  final int netConducteurPlace;

  /// Totaux si toutes les places proposées sont payées.
  final int totalPayePassagers;
  final int commissionKovoit;
  final int netConducteur;
  final double tauxCommissionPct;

  /// Ce que le trajet coûte réellement au conducteur avec [paidSeats] places payées : les places
  /// vides ne sont pas compensées. Arrondi au franc pour l'affichage.
  int driverShareFor(int paidSeats) => (coutTotal - netConducteurPlace * paidSeats).round();

  static double _d(Object? value) => double.parse('$value');

  /// Instantané renvoyé par `POST /trajets/estimation/` et `tarification` d'un trajet publié.
  factory PriceBreakdown.fromJson(Map<String, dynamic> json) {
    final parametres = json['parametres'] as Map<String, dynamic>;
    return PriceBreakdown(
      formuleVersion: json['formule_version'] as String,
      typeVehicule: json['type_vehicule'] as String,
      distanceKm: _d(json['distance_km']),
      dureeMin: json['duree_min'] as int,
      estimatedRoute: json['source_itineraire'] == 'estimation',
      passagersPrevus: json['passagers_prevus'] as int,
      consommationL100km: _d(json['consommation_retenue_l_100km']),
      vehicleConsumption: parametres['source_consommation'] == 'vehicule',
      carburantLitres: _d(json['carburant_litres']),
      prixCarburantLitre: _d(parametres['prix_carburant_litre']),
      coutCarburant: _d(json['cout_carburant']),
      coutTemps: _d(json['cout_temps']),
      coutEntretien: _d(json['cout_entretien']),
      coutTotal: _d(json['cout_total']),
      partConducteur: _d(json['part_conducteur']),
      contributionPassagers: _d(json['contribution_passagers']),
      prixPlace: json['prix_place'] as int,
      commissionPlace: json['commission_place'] as int,
      netConducteurPlace: json['net_conducteur_place'] as int,
      totalPayePassagers: json['total_paye_passagers'] as int,
      commissionKovoit: json['commission_kovoit'] as int,
      netConducteur: json['net_conducteur'] as int,
      tauxCommissionPct: _d(parametres['taux_commission_pct']),
    );
  }
}
