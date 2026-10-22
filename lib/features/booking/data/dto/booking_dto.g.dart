// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookingDto _$BookingDtoFromJson(Map<String, dynamic> json) => BookingDto(
  id: json['id'] as String,
  trajet: TripDto.fromJson(json['trajet'] as Map<String, dynamic>),
  statut: json['statut'] as String,
  montantTotal: (json['montant_total'] as num).toInt(),
  creeLe: DateTime.parse(json['cree_le'] as String),
  point: json['point'] == null
      ? null
      : PickupPointDto.fromJson(json['point'] as Map<String, dynamic>),
  arriveeLibelle: json['arrivee_libelle'] as String? ?? '',
  prix: (json['prix'] as num?)?.toInt(),
  fraisService: (json['frais_service'] as num?)?.toInt(),
  complementPaye: (json['complement_paye'] as num?)?.toInt() ?? 0,
  annulationTardive: json['annulation_tardive'] as bool? ?? false,
  codeDepart: json['code_depart'] as String?,
);

Map<String, dynamic> _$BookingDtoToJson(BookingDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'trajet': instance.trajet.toJson(),
      'statut': instance.statut,
      'point': instance.point?.toJson(),
      'arrivee_libelle': instance.arriveeLibelle,
      'prix': instance.prix,
      'frais_service': instance.fraisService,
      'montant_total': instance.montantTotal,
      'complement_paye': instance.complementPaye,
      'annulation_tardive': instance.annulationTardive,
      'cree_le': instance.creeLe.toIso8601String(),
      'code_depart': instance.codeDepart,
    };
