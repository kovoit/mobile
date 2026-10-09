import 'package:json_annotation/json_annotation.dart';

import '../../../auth/domain/entities/app_user.dart';
import '../../domain/entities/kyc_dossier.dart';

part 'kyc_dossier_dto.g.dart';

/// Objet `dossier` de l'API (voir docs/api/kyc.md).
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class KycDossierDto {
  const KycDossierDto({required this.type, required this.statut, required this.pieces, this.motifRejet});

  factory KycDossierDto.fromJson(Map<String, dynamic> json) => _$KycDossierDtoFromJson(json);

  final String type;
  final String statut;
  final String? motifRejet;
  final List<KycPieceDto> pieces;

  Map<String, dynamic> toJson() => _$KycDossierDtoToJson(this);

  KycDossier toEntity() => KycDossier(
        type: KycType.fromApi(type) ?? KycType.passager,
        status: KycStatus.fromApi(statut),
        motifRejet: motifRejet,
        pieces: [
          for (final piece in pieces)
            if (KycPieceType.fromApi(piece.typePiece) case final type?) KycPiece(type: type, provided: piece.fournie),
        ],
      );
}

@JsonSerializable(fieldRename: FieldRename.snake)
class KycPieceDto {
  const KycPieceDto({required this.typePiece, required this.fournie});

  factory KycPieceDto.fromJson(Map<String, dynamic> json) => _$KycPieceDtoFromJson(json);

  final String typePiece;
  final bool fournie;

  Map<String, dynamic> toJson() => _$KycPieceDtoToJson(this);
}
