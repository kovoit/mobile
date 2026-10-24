// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SearchMatchDto _$SearchMatchDtoFromJson(Map<String, dynamic> json) =>
    SearchMatchDto(
      trajet: TripDto.fromJson(json['trajet'] as Map<String, dynamic>),
      pointPropose: PickupPointDto.fromJson(
        json['point_propose'] as Map<String, dynamic>,
      ),
      distanceMarcheKm: (json['distance_marche_km'] as num).toDouble(),
      ecartMinutes: (json['ecart_minutes'] as num?)?.toInt() ?? 0,
      prixPassager: (json['prix_passager'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SearchMatchDtoToJson(SearchMatchDto instance) =>
    <String, dynamic>{
      'trajet': instance.trajet.toJson(),
      'point_propose': instance.pointPropose.toJson(),
      'distance_marche_km': instance.distanceMarcheKm,
      'ecart_minutes': instance.ecartMinutes,
      'prix_passager': instance.prixPassager,
    };
