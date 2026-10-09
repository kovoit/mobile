// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ItineraryDto _$ItineraryDtoFromJson(Map<String, dynamic> json) => ItineraryDto(
  distanceKm: (json['distance_km'] as num).toDouble(),
  dureeMin: (json['duree_min'] as num).toInt(),
  points:
      (json['points'] as List<dynamic>?)
          ?.map(
            (e) =>
                (e as List<dynamic>).map((e) => (e as num).toDouble()).toList(),
          )
          .toList() ??
      const [],
);

Map<String, dynamic> _$ItineraryDtoToJson(ItineraryDto instance) =>
    <String, dynamic>{
      'distance_km': instance.distanceKm,
      'duree_min': instance.dureeMin,
      'points': instance.points,
    };

SearchResponseDto _$SearchResponseDtoFromJson(Map<String, dynamic> json) =>
    SearchResponseDto(
      itineraire: ItineraryDto.fromJson(
        json['itineraire'] as Map<String, dynamic>,
      ),
      resultats: (json['resultats'] as List<dynamic>)
          .map((e) => TripDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SearchResponseDtoToJson(SearchResponseDto instance) =>
    <String, dynamic>{
      'itineraire': instance.itineraire.toJson(),
      'resultats': instance.resultats.map((e) => e.toJson()).toList(),
    };
