import '../../../auth/domain/entities/app_user.dart';

enum KycType {
  passager('passager'),
  conducteur('conducteur');

  const KycType(this.apiValue);

  final String apiValue;

  static KycType? fromApi(String? value) => values.where((t) => t.apiValue == value).firstOrNull;
}

/// Pièces demandées (spéc. §KYC + maquette « Vérification d'identité »).
enum KycPieceType {
  photoProfil('photo_profil'),
  identiteRecto('identite_recto'),
  identiteVerso('identite_verso'),
  selfie('selfie'),
  permis('permis'),
  carteGriseOuAssurance('carte_grise_ou_assurance'),
  photoVehicule('photo_vehicule');

  const KycPieceType(this.apiValue);

  final String apiValue;

  /// Le selfie se prend en direct (caméra frontale), jamais depuis la galerie.
  bool get requiresLiveCapture => this == KycPieceType.selfie;

  static KycPieceType? fromApi(String? value) => values.where((p) => p.apiValue == value).firstOrNull;
}

class KycPiece {
  const KycPiece({required this.type, required this.provided});

  final KycPieceType type;
  final bool provided;
}

/// Dossier KYC tel que renvoyé par l'API. Le statut est décidé par l'administrateur.
class KycDossier {
  const KycDossier({required this.type, required this.status, required this.pieces, this.motifRejet});

  final KycType type;
  final KycStatus status;
  final List<KycPiece> pieces;
  final String? motifRejet;

  int get providedCount => pieces.where((p) => p.provided).length;

  bool get isComplete => pieces.isNotEmpty && providedCount == pieces.length;

  /// Première pièce manquante, dans l'ordre de la maquette.
  KycPiece? get nextMissing => pieces.where((p) => !p.provided).firstOrNull;

  /// Les pièces ne sont modifiables que tant que le dossier n'est pas envoyé (ou s'il a été rejeté).
  bool get isEditable => status == KycStatus.nonVerifie || status == KycStatus.rejete;
}
