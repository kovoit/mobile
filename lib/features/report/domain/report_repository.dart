/// Motifs de signalement (docs/api/after_trip.md).
enum ReportReason {
  retard('retard', 'Retard important'),
  comportement('comportement', 'Comportement inapproprié'),
  securite('securite', 'Problème de sécurité'),
  vehicule('vehicule', 'Véhicule non conforme'),
  paiement('paiement', 'Problème de paiement'),
  autre('autre', 'Autre');

  const ReportReason(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

/// « Signaler un problème » pendant ou après le trajet, vers l'administrateur (spéc. §Sécurité).
abstract interface class ReportRepository {
  static const int maxDescriptionLength = 1000;

  Future<void> report({required int bookingId, required ReportReason reason, required String description});
}
