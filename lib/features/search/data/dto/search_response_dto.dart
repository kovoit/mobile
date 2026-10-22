import 'package:json_annotation/json_annotation.dart';

import '../../../trip/data/dto/trip_dto.dart';
import '../../../trip/domain/entities/trip.dart';

part 'search_response_dto.g.dart';

/// Un résultat de `GET /trajets/recherche/` (backend : ResultatRechercheSerializer).
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class SearchMatchDto {
  const SearchMatchDto({
    required this.trajet,
    required this.pointPropose,
    required this.distanceMarcheKm,
    this.ecartMinutes = 0,
  });

  factory SearchMatchDto.fromJson(Map<String, dynamic> json) => _$SearchMatchDtoFromJson(json);

  final TripDto trajet;

  /// Point de prise en charge le plus proche du départ du passager (choisi par le backend).
  final PickupPointDto pointPropose;
  final double distanceMarcheKm;
  final int ecartMinutes;

  Map<String, dynamic> toJson() => _$SearchMatchDtoToJson(this);

  Trip toEntity() => trajet.toEntity().withMatch(pickupId: pointPropose.id, walkingDistanceKm: distanceMarcheKm);
}
