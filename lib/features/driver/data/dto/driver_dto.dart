import 'package:json_annotation/json_annotation.dart';

import '../../../booking/domain/entities/booking.dart';
import '../../../trip/data/dto/trip_dto.dart';
import '../../domain/entities/driver_trip.dart';

part 'driver_dto.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class PassengerSummaryDto {
  const PassengerSummaryDto({
    required this.id,
    required this.prenom,
    required this.nom,
    this.verifie = false,
    this.photo,
    this.note,
  });

  factory PassengerSummaryDto.fromJson(Map<String, dynamic> json) => _$PassengerSummaryDtoFromJson(json);

  final int id;
  final String prenom;
  final String nom;
  final bool verifie;
  final String? photo;
  final double? note;

  Map<String, dynamic> toJson() => _$PassengerSummaryDtoToJson(this);

  PassengerSummary toEntity() =>
      PassengerSummary(id: id, prenom: prenom, nom: nom, verifie: verifie, photoUrl: photo, note: note);
}

/// Objet `demande_conducteur` : volontairement sans champ `code_depart`.
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class DriverRequestDto {
  const DriverRequestDto({
    required this.id,
    required this.passager,
    required this.nbPlaces,
    required this.statut,
    required this.methodePaiement,
    required this.statutPaiement,
    required this.montant,
    this.pointPriseEnChargeId,
    this.actions = const [],
  });

  factory DriverRequestDto.fromJson(Map<String, dynamic> json) => _$DriverRequestDtoFromJson(json);

  final int id;
  final PassengerSummaryDto passager;
  final int nbPlaces;
  final String statut;
  final String methodePaiement;
  final String statutPaiement;
  final int montant;
  final int? pointPriseEnChargeId;
  final List<String> actions;

  Map<String, dynamic> toJson() => _$DriverRequestDtoToJson(this);

  DriverRequest toEntity() => DriverRequest(
        id: id,
        passenger: passager.toEntity(),
        places: nbPlaces,
        status: BookingStatus.fromApi(statut),
        paymentMethod: PaymentMethod.fromApi(methodePaiement),
        paymentStatus: PaymentStatus.fromApi(statutPaiement),
        montant: montant,
        pickupPointId: pointPriseEnChargeId,
        actions: {for (final a in actions) ?DriverRequestAction.fromApi(a)},
      );
}

/// Objet `trajet_conducteur` (docs/api/driver.md).
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class DriverTripDto {
  const DriverTripDto({
    required this.id,
    required this.depart,
    required this.arrivee,
    required this.pointsPriseEnCharge,
    required this.departLe,
    required this.placesTotal,
    required this.placesRestantes,
    required this.prixPlace,
    required this.statut,
    this.economie = 0,
    this.demandes = const [],
    this.actions = const [],
  });

  factory DriverTripDto.fromJson(Map<String, dynamic> json) => _$DriverTripDtoFromJson(json);

  final int id;
  final GeoPlaceDto depart;
  final GeoPlaceDto arrivee;
  final List<PickupPointDto> pointsPriseEnCharge;
  final DateTime departLe;
  final int placesTotal;
  final int placesRestantes;
  final int prixPlace;
  final String statut;
  final int economie;
  final List<DriverRequestDto> demandes;
  final List<String> actions;

  Map<String, dynamic> toJson() => _$DriverTripDtoToJson(this);

  DriverTrip toEntity() => DriverTrip(
        id: id,
        depart: depart.toEntity(),
        arrivee: arrivee.toEntity(),
        pickupPoints: [for (final p in pointsPriseEnCharge) p.toEntity()]..sort((a, b) => a.ordre.compareTo(b.ordre)),
        departureAt: departLe,
        placesTotal: placesTotal,
        placesRestantes: placesRestantes,
        prixPlace: prixPlace,
        status: TripStatus.fromApi(statut),
        economie: economie,
        requests: [for (final d in demandes) d.toEntity()],
        actions: {for (final a in actions) ?DriverTripAction.fromApi(a)},
      );
}

@JsonSerializable(fieldRename: FieldRename.snake)
class PriceEstimateDto {
  const PriceEstimateDto({required this.prixPlace, required this.distanceKm, required this.dureeMin});

  factory PriceEstimateDto.fromJson(Map<String, dynamic> json) => _$PriceEstimateDtoFromJson(json);

  final int prixPlace;
  final double distanceKm;
  final int dureeMin;

  Map<String, dynamic> toJson() => _$PriceEstimateDtoToJson(this);

  PriceEstimate toEntity() => PriceEstimate(prixPlace: prixPlace, distanceKm: distanceKm, durationMin: dureeMin);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class SavingsDto {
  const SavingsDto({required this.mois, required this.total, required this.places});

  factory SavingsDto.fromJson(Map<String, dynamic> json) => _$SavingsDtoFromJson(json);

  /// `AAAA-MM`
  final String mois;
  final int total;
  final int places;

  Map<String, dynamic> toJson() => _$SavingsDtoToJson(this);

  DriverSavings toEntity() {
    final parts = mois.split('-');
    return DriverSavings(
      month: DateTime.utc(int.parse(parts[0]), int.parse(parts[1])),
      total: total,
      places: places,
    );
  }
}
