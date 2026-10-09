// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kyc_dossier_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KycDossierDto _$KycDossierDtoFromJson(Map<String, dynamic> json) =>
    KycDossierDto(
      type: json['type'] as String,
      statut: json['statut'] as String,
      pieces: (json['pieces'] as List<dynamic>)
          .map((e) => KycPieceDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      motifRejet: json['motif_rejet'] as String?,
    );

Map<String, dynamic> _$KycDossierDtoToJson(KycDossierDto instance) =>
    <String, dynamic>{
      'type': instance.type,
      'statut': instance.statut,
      'motif_rejet': instance.motifRejet,
      'pieces': instance.pieces.map((e) => e.toJson()).toList(),
    };

KycPieceDto _$KycPieceDtoFromJson(Map<String, dynamic> json) => KycPieceDto(
  typePiece: json['type_piece'] as String,
  fournie: json['fournie'] as bool,
);

Map<String, dynamic> _$KycPieceDtoToJson(KycPieceDto instance) =>
    <String, dynamic>{
      'type_piece': instance.typePiece,
      'fournie': instance.fournie,
    };
