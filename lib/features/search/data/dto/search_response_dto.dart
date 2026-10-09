import 'package:json_annotation/json_annotation.dart';

import '../../../trip/data/dto/trip_dto.dart';
import '../../domain/entities/search_query.dart';
import '../../domain/entities/search_result.dart';

part 'search_response_dto.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ItineraryDto {
  const ItineraryDto({required this.distanceKm, required this.dureeMin, this.points = const []});

  factory ItineraryDto.fromJson(Map<String, dynamic> json) => _$ItineraryDtoFromJson(json);

  final double distanceKm;
  final int dureeMin;

  /// `[[lat, lng], …]`
  final List<List<double>> points;

  Map<String, dynamic> toJson() => _$ItineraryDtoToJson(this);

  Itinerary toEntity() => Itinerary(
        distanceKm: distanceKm,
        durationMin: dureeMin,
        points: [
          for (final p in points)
            if (p.length == 2) (p[0], p[1]),
        ],
      );
}

/// Réponse de `GET /trajets/recherche/`.
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class SearchResponseDto {
  const SearchResponseDto({required this.itineraire, required this.resultats});

  factory SearchResponseDto.fromJson(Map<String, dynamic> json) => _$SearchResponseDtoFromJson(json);

  final ItineraryDto itineraire;
  final List<TripDto> resultats;

  Map<String, dynamic> toJson() => _$SearchResponseDtoToJson(this);

  SearchResult toEntity() => SearchResult(
        itinerary: itineraire.toEntity(),
        trips: [for (final t in resultats) t.toEntity()],
      );
}
