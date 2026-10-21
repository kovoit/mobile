import '../../../auth/domain/entities/app_user.dart';

enum KycType {
  passager('passager'),
  conducteur('conducteur');

  const KycType(this.apiValue);

  final String apiValue;

  static KycType? fromApi(String? value) => values.where((t) => t.apiValue == value).firstOrNull;
}

/// Type de pièce envoyé au backend (`type_piece`).
enum KycPieceType {
  identite('identite'),
  selfie('selfie'),
  permis('permis'),
  carteGrise('carte_grise'),
  assurance('assurance'),
  photoVehicule('photo_vehicule');

  const KycPieceType(this.apiValue);

  final String apiValue;

  static KycPieceType? fromApi(String? value) => values.where((p) => p.apiValue == value).firstOrNull;
}

/// Emplacement à remplir dans un dossier, dans l'ordre d'affichage.
/// `vehiculeDocument` accepte la carte grise OU l'assurance (une seule suffit côté backend).
enum KycSlot {
  identite('identite', [KycPieceType.identite]),
  selfie('selfie', [KycPieceType.selfie]),
  permis('permis', [KycPieceType.permis]),
  vehiculeDocument('carte_grise_ou_assurance', [KycPieceType.carteGrise, KycPieceType.assurance]),
  photoVehicule('photo_vehicule', [KycPieceType.photoVehicule]);

  const KycSlot(this.apiValue, this.accepts);

  /// Valeur dans `pieces_manquantes`.
  final String apiValue;
  final List<KycPieceType> accepts;

  /// Le selfie se prend en direct (caméra frontale), jamais depuis la galerie.
  bool get requiresLiveCapture => this == KycSlot.selfie;

  /// Plusieurs types de pièce possibles : l'utilisateur choisit lequel il envoie.
  bool get hasChoice => accepts.length > 1;

  static KycSlot? fromMissing(String value) => values.where((s) => s.apiValue == value).firstOrNull;

  static KycSlot? fromPiece(KycPieceType piece) => values.where((s) => s.accepts.contains(piece)).firstOrNull;
}

class KycPiece {
  const KycPiece({required this.type, required this.provided, this.providedAs});

  final KycSlot type;
  final bool provided;

  /// Pièce effectivement envoyée (ex. assurance plutôt que carte grise).
  final KycPieceType? providedAs;
}

/// Dossier KYC tel que renvoyé par l'API. Le statut est décidé par l'administrateur.
class KycDossier {
  const KycDossier({required this.type, required this.status, required this.pieces, this.motifRejet});

  final KycType type;
  final KycStatus status;

  /// Pièces fournies et pièces manquantes (`pieces_manquantes`), dans l'ordre d'affichage.
  final List<KycPiece> pieces;
  final String? motifRejet;

  int get providedCount => pieces.where((p) => p.provided).length;

  bool get isComplete => pieces.isNotEmpty && providedCount == pieces.length;

  /// Première pièce manquante, dans l'ordre d'affichage.
  KycPiece? get nextMissing => pieces.where((p) => !p.provided).firstOrNull;

  /// Les pièces ne sont modifiables que tant que le dossier n'est pas envoyé (ou s'il a été rejeté).
  bool get isEditable => status == KycStatus.nonVerifie || status == KycStatus.rejete;
}
