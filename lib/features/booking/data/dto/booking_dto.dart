import 'package:json_annotation/json_annotation.dart';

import '../../../trip/data/dto/trip_dto.dart';
import '../../domain/entities/booking.dart';

part 'booking_dto.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class PaymentDto {
  const PaymentDto({
    required this.methode,
    required this.statut,
    required this.montant,
    this.telephone,
    this.reference,
    this.message,
  });

  factory PaymentDto.fromJson(Map<String, dynamic> json) => _$PaymentDtoFromJson(json);

  final String methode;
  final String statut;
  final int montant;
  final String? telephone;
  final String? reference;
  final String? message;

  Map<String, dynamic> toJson() => _$PaymentDtoToJson(this);

  Payment toEntity() => Payment(
        method: PaymentMethod.fromApi(methode),
        status: PaymentStatus.fromApi(statut),
        montant: montant,
        telephone: telephone,
        reference: reference,
        message: message,
      );
}

@JsonSerializable(fieldRename: FieldRename.snake)
class DriverPositionDto {
  const DriverPositionDto({required this.lat, required this.lng, this.majLe});

  factory DriverPositionDto.fromJson(Map<String, dynamic> json) => _$DriverPositionDtoFromJson(json);

  final double lat;
  final double lng;
  final DateTime? majLe;

  Map<String, dynamic> toJson() => _$DriverPositionDtoToJson(this);
}

/// Objet `reservation` (docs/api/bookings.md).
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class BookingDto {
  const BookingDto({
    required this.id,
    required this.trajet,
    required this.nbPlaces,
    required this.statut,
    required this.prixTotal,
    required this.paiement,
    required this.creeLe,
    this.fraisService = 0,
    this.pointPriseEnChargeId,
    this.codeDepart,
    this.annulationGratuiteJusquAu,
    this.annulationTardive = false,
    this.conducteurTelephone,
    this.positionConducteur,
    this.arriveeConducteurMin,
    this.actions = const [],
  });

  factory BookingDto.fromJson(Map<String, dynamic> json) => _$BookingDtoFromJson(json);

  final int id;
  final TripDto trajet;
  final int nbPlaces;
  final String statut;
  final int prixTotal;
  final int fraisService;
  final PaymentDto paiement;
  final DateTime creeLe;
  final int? pointPriseEnChargeId;
  final String? codeDepart;
  final DateTime? annulationGratuiteJusquAu;
  final bool annulationTardive;
  final String? conducteurTelephone;
  final DriverPositionDto? positionConducteur;
  final int? arriveeConducteurMin;
  final List<String> actions;

  Map<String, dynamic> toJson() => _$BookingDtoToJson(this);

  Booking toEntity() => Booking(
        id: id,
        trip: trajet.toEntity(),
        places: nbPlaces,
        status: BookingStatus.fromApi(statut),
        prixTotal: prixTotal,
        fraisService: fraisService,
        payment: paiement.toEntity(),
        createdAt: creeLe,
        pickupPointId: pointPriseEnChargeId,
        departureCode: codeDepart,
        freeCancellationUntil: annulationGratuiteJusquAu,
        lateCancellation: annulationTardive,
        driverPhone: conducteurTelephone,
        driverPosition: positionConducteur == null ? null : (positionConducteur!.lat, positionConducteur!.lng),
        driverEtaMin: arriveeConducteurMin,
        actions: {for (final a in actions) ?BookingAction.fromApi(a)},
      );
}
