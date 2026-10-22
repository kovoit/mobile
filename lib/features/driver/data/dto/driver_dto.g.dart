// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DriverRequestDto _$DriverRequestDtoFromJson(Map<String, dynamic> json) =>
    DriverRequestDto(
      id: json['id'] as String,
      passager: PersonDto.fromJson(json['passager'] as Map<String, dynamic>),
      statut: json['statut'] as String,
      montantTotal: (json['montant_total'] as num).toInt(),
      point: json['point'] == null
          ? null
          : PickupPointDto.fromJson(json['point'] as Map<String, dynamic>),
      prix: (json['prix'] as num?)?.toInt(),
      essaisCode: (json['essais_code'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$DriverRequestDtoToJson(DriverRequestDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'passager': instance.passager.toJson(),
      'statut': instance.statut,
      'point': instance.point?.toJson(),
      'prix': instance.prix,
      'montant_total': instance.montantTotal,
      'essais_code': instance.essaisCode,
    };

TripSavingDto _$TripSavingDtoFromJson(Map<String, dynamic> json) =>
    TripSavingDto(
      trajetId: json['trajet_id'] as String,
      departLe: DateTime.parse(json['depart_le'] as String),
      depart: json['depart'] as String,
      arrivee: json['arrivee'] as String,
      montant: (json['montant'] as num).toInt(),
    );

Map<String, dynamic> _$TripSavingDtoToJson(TripSavingDto instance) =>
    <String, dynamic>{
      'trajet_id': instance.trajetId,
      'depart_le': instance.departLe.toIso8601String(),
      'depart': instance.depart,
      'arrivee': instance.arrivee,
      'montant': instance.montant,
    };

SavingsDto _$SavingsDtoFromJson(Map<String, dynamic> json) => SavingsDto(
  moisEnCours: (json['mois_en_cours'] as num).toInt(),
  total: (json['total'] as num).toInt(),
  parTrajet:
      (json['par_trajet'] as List<dynamic>?)
          ?.map((e) => TripSavingDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$SavingsDtoToJson(SavingsDto instance) =>
    <String, dynamic>{
      'mois_en_cours': instance.moisEnCours,
      'total': instance.total,
      'par_trajet': instance.parTrajet.map((e) => e.toJson()).toList(),
    };
