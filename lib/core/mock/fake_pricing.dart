/// Tarification simulée (`Env.useMockApi` et tests) : même formule et même JSON que le backend
/// (apps/tarification/calcul.py, TarificationSerializer), avec les valeurs de départ des
/// paramètres. Jamais utilisée avec le vrai backend : le prix vient alors toujours de l'API.
abstract final class FakePricing {
  static const double prixCarburantLitre = 817;
  static const double consommationVoiture = 8;
  static const double consommationMoto = 3;
  static const double tauxCommissionPct = 15;
  static const double coutHoraire = 300;
  static const double entretienVoitureKm = 15;
  static const double entretienMotoKm = 5;
  static const int arrondi = 5;

  /// (commission, net conducteur) d'un paiement : commission + net == prix.
  static (int, int) repartir(int prix) {
    final commission = (prix * tauxCommissionPct / 100).round();
    return (commission, prix - commission);
  }

  static String _s(double v) => v.toStringAsFixed(3);

  static Map<String, dynamic> snapshot({
    required double distanceKm,
    required int places,
    String typeVehicule = 'voiture',
  }) {
    final consommation = typeVehicule == 'moto' ? consommationMoto : consommationVoiture;
    final duree = (distanceKm / 25 * 60).round();
    final litres = distanceKm * consommation / 100;
    final carburant = litres * prixCarburantLitre;
    final temps = duree / 60 * coutHoraire;
    final entretienKm = typeVehicule == 'moto' ? entretienMotoKm : entretienVoitureKm;
    final entretien = distanceKm * entretienKm;
    final total = carburant + temps + entretien;
    final part = total / (places + 1);
    final contribution = total - part;
    final brut = contribution / (1 - tauxCommissionPct / 100);
    final prix = ((brut / places) / arrondi).ceil() * arrondi;
    final (commission, net) = repartir(prix);
    return {
      'formule_version': 'v1',
      'type_vehicule': typeVehicule,
      'distance_km': _s(distanceKm),
      'duree_min': duree,
      'source_itineraire': 'routage',
      'passagers_prevus': places,
      'consommation_retenue_l_100km': _s(consommation),
      'carburant_litres': _s(litres),
      'cout_carburant': _s(carburant),
      'cout_temps': _s(temps),
      'cout_entretien': _s(entretien),
      'cout_total': _s(total),
      'part_conducteur': _s(part),
      'contribution_passagers': _s(contribution),
      'montant_brut_passagers': _s(brut),
      'prix_place': prix,
      'commission_place': commission,
      'net_conducteur_place': net,
      'total_paye_passagers': prix * places,
      'commission_kovoit': commission * places,
      'net_conducteur': net * places,
      'parametres': {
        'prix_carburant_litre': _s(prixCarburantLitre),
        'consommation_l_100km': _s(consommation),
        'source_consommation': 'reference_$typeVehicule',
        'majoration_charge_par_passager_pct': '0.000',
        'cout_horaire_conducteur': _s(coutHoraire),
        'entretien_par_km': _s(entretienKm),
        'taux_commission_pct': _s(tauxCommissionPct),
        'arrondi_prix_fcfa': arrondi,
        'prix_minimum_place': 0,
      },
    };
  }
}
