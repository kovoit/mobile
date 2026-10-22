import 'package:json_annotation/json_annotation.dart';

import '../../../booking/domain/entities/booking.dart';
import '../../../trip/data/dto/trip_dto.dart';
import '../../../trip/domain/entities/geo_place.dart';
import '../../domain/entities/driver_trip.dart';

part 'driver_dto.g.dart';

/// Réservation vue par le conducteur (backend : ReservationConducteurSerializer).
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class DriverRequestDto {
  const DriverRequestDto({
    required this.id,
    required this.passager,
    required this.statut,
    required this.montantTotal,
    this.point,
    this.prix,
    this.essaisCode = 0,
  });

  factory DriverRequestDto.fromJson(Map<String, dynamic> json) => _$DriverRequestDtoFromJson(json);

  final String id;
  final PersonDto passager;
  final String statut;
  final PickupPointDto? point;
  final int? prix;
  final int montantTotal;
  final int essaisCode;

  Map<String, dynamic> toJson() => _$DriverRequestDtoToJson(this);

  DriverRequest toEntity() => DriverRequest(
        id: id,
        passenger: PassengerSummary(
          id: passager.id,
          prenom: passager.prenom,
          nom: passager.nom,
          verifie: passager.confiance.passagerVerifie,
          photoUrl: passager.photo,
          note: passager.confiance.noteMoyenne,
        ),
        status: BookingStatus.fromApi(statut),
        montant: prix ?? montantTotal,
        pickupPointId: point?.id,
        essaisCode: essaisCode,
      );
}

/// Trajet du conducteur (backend : TrajetConducteurSerializer = TrajetSerializer + `nb_demandes`).
class DriverTripDto {
  const DriverTripDto({required this.trajet, this.nbDemandes = 0});

  factory DriverTripDto.fromJson(Map<String, dynamic> json) =>
      DriverTripDto(trajet: TripDto.fromJson(json), nbDemandes: json['nb_demandes'] as int? ?? 0);

  final TripDto trajet;
  final int nbDemandes;

  DriverTrip toEntity() {
    final trip = trajet.toEntity();
    return DriverTrip(
      id: trip.id,
      depart: trip.depart,
      arrivee: trip.arrivee,
      pickupPoints: trip.pickupPoints,
      departureAt: trip.departureAt,
      placesTotal: trajet.placesTotal,
      placesRestantes: trip.placesRestantes,
      prixPlace: trip.prixPlace,
      status: TripStatus.fromApi(trip.statut),
      nbDemandes: nbDemandes,
    );
  }
}

@JsonSerializable(fieldRename: FieldRename.snake)
class TripSavingDto {
  const TripSavingDto({
    required this.trajetId,
    required this.departLe,
    required this.depart,
    required this.arrivee,
    required this.montant,
  });

  factory TripSavingDto.fromJson(Map<String, dynamic> json) => _$TripSavingDtoFromJson(json);

  final String trajetId;
  final DateTime departLe;
  final String depart;
  final String arrivee;
  final int montant;

  Map<String, dynamic> toJson() => _$TripSavingDtoToJson(this);

  TripSaving toEntity() =>
      TripSaving(tripId: trajetId, departureAt: departLe, depart: depart, arrivee: arrivee, montant: montant);
}

/// `GET /moi/economies/` (backend : EconomiesSerializer).
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class SavingsDto {
  const SavingsDto({required this.moisEnCours, required this.total, this.parTrajet = const []});

  factory SavingsDto.fromJson(Map<String, dynamic> json) => _$SavingsDtoFromJson(json);

  final int moisEnCours;
  final int total;
  final List<TripSavingDto> parTrajet;

  Map<String, dynamic> toJson() => _$SavingsDtoToJson(this);

  DriverSavings toEntity() =>
      DriverSavings(moisEnCours: moisEnCours, total: total, parTrajet: [for (final t in parTrajet) t.toEntity()]);
}

/// Corps de `POST /trajets/` (backend : PublicationSerializer).
Map<String, dynamic> publicationBody(TripDraft draft, {required String vehiculeId}) {
  Map<String, dynamic> point(GeoPlace p) => {'lat': p.lat, 'lng': p.lng, 'libelle': p.libelle};
  return {
    'vehicule_id': vehiculeId,
    'depart_lat': draft.depart.lat,
    'depart_lng': draft.depart.lng,
    'depart_libelle': draft.depart.libelle,
    'arrivee_lat': draft.arrivee.lat,
    'arrivee_lng': draft.arrivee.lng,
    'arrivee_libelle': draft.arrivee.libelle,
    'depart_le': draft.departureAt.toUtc().toIso8601String(),
    'places': draft.places,
    'points': [for (final p in draft.pickupPoints) point(p)],
  };
}
