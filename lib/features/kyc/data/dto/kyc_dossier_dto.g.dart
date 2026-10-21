// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kyc_dossier_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KycDossierDto _$KycDossierDtoFromJson(Map<String, dynamic> json) =>
    KycDossierDto(
      type: json['type'] as String,
      statut: json['statut'] as String,
      pieces:
          (json['pieces'] as List<dynamic>?)
              ?.map((e) => KycPieceDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      piecesManquantes:
          (json['pieces_manquantes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      motifRejet: json['motif_rejet'] as String? ?? '',
    );

KycPieceDto _$KycPieceDtoFromJson(Map<String, dynamic> json) =>
    KycPieceDto(typePiece: json['type_piece'] as String);
