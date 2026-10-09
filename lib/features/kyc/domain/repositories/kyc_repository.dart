import '../entities/kyc_dossier.dart';

/// Dossiers KYC (validation manuelle par l'administrateur dans le MVP).
abstract interface class KycRepository {
  Future<Map<KycType, KycDossier>> fetchDossiers();

  /// Envoie une pièce. Le fichier local est supprimé après l'envoi (données sensibles).
  Future<KycDossier> uploadPiece({required KycType type, required KycPieceType piece, required String filePath});

  /// Soumet le dossier complet : il passe « en attente » de validation.
  Future<KycDossier> submit(KycType type);
}
