import 'package:json_annotation/json_annotation.dart';

import '../../../auth/domain/entities/app_user.dart';
import '../../domain/entities/kyc_dossier.dart';

part 'kyc_dossier_dto.g.dart';

/// `DossierSerializer` du backend (`GET /kyc/`, `POST /kyc/<type>/pieces/`, `POST /kyc/<type>/soumettre/`).
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class KycDossierDto {
  const KycDossierDto({
    required this.type,
    required this.statut,
    this.pieces = const [],
    this.piecesManquantes = const [],
    this.motifRejet = '',
  });

  factory KycDossierDto.fromJson(Map<String, dynamic> json) => _$KycDossierDtoFromJson(json);

  final String type;
  final String statut;
  final String? motifRejet;
  final List<KycPieceDto> pieces;

  /// Emplacements encore vides (`carte_grise_ou_assurance` pour le document du véhicule).
  final List<String> piecesManquantes;

  KycDossier toEntity() {
    // Les types inconnus du mobile sont ignorés.
    final provided = <KycSlot, KycPieceType>{};
    for (final piece in pieces) {
      final type = KycPieceType.fromApi(piece.typePiece);
      final slot = type == null ? null : KycSlot.fromPiece(type);
      if (slot != null) provided[slot] = type!;
    }
    final missing = piecesManquantes.map(KycSlot.fromMissing).nonNulls.toSet();
    return KycDossier(
      type: KycType.fromApi(type) ?? KycType.passager,
      status: KycStatus.fromApi(statut),
      motifRejet: (motifRejet ?? '').isEmpty ? null : motifRejet,
      pieces: [
        for (final slot in KycSlot.values)
          if (provided.containsKey(slot))
            KycPiece(type: slot, provided: true, providedAs: provided[slot])
          else if (missing.contains(slot))
            KycPiece(type: slot, provided: false),
      ],
    );
  }
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class KycPieceDto {
  const KycPieceDto({required this.typePiece});

  factory KycPieceDto.fromJson(Map<String, dynamic> json) => _$KycPieceDtoFromJson(json);

  final String typePiece;
}
