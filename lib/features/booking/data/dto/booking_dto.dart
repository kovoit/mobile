import 'package:json_annotation/json_annotation.dart';

import '../../../trip/data/dto/trip_dto.dart';
import '../../domain/entities/booking.dart';

part 'booking_dto.g.dart';

/// Réservation vue par le passager (backend : ReservationPassagerSerializer).
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class BookingDto {
  const BookingDto({
    required this.id,
    required this.trajet,
    required this.statut,
    required this.montantTotal,
    required this.creeLe,
    this.point,
    this.arriveeLibelle = '',
    this.prix,
    this.fraisService,
    this.complementPaye = 0,
    this.annulationTardive = false,
    this.codeDepart,
  });

  factory BookingDto.fromJson(Map<String, dynamic> json) => _$BookingDtoFromJson(json);

  final String id;
  final TripDto trajet;
  final String statut;
  final PickupPointDto? point;
  final String arriveeLibelle;
  final int? prix;
  final int? fraisService;
  final int montantTotal;
  final int complementPaye;
  final bool annulationTardive;
  final DateTime creeLe;

  /// Présent seulement pour le passager, réservation acceptée.
  final String? codeDepart;

  Map<String, dynamic> toJson() => _$BookingDtoToJson(this);

  Booking toEntity() {
    final trip = trajet.toEntity();
    return Booking(
      id: id,
      trip: point == null ? trip : trip.withMatch(pickupId: point!.id),
      status: BookingStatus.fromApi(statut),
      montantTotal: montantTotal,
      prix: prix,
      fraisService: fraisService ?? 0,
      complementPaye: complementPaye,
      createdAt: creeLe,
      pickupPointId: point?.id,
      arriveeLibelle: arriveeLibelle,
      departureCode: codeDepart,
      lateCancellation: annulationTardive,
    );
  }
}
