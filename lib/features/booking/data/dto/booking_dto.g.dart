// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentDto _$PaymentDtoFromJson(Map<String, dynamic> json) => PaymentDto(
  methode: json['methode'] as String,
  statut: json['statut'] as String,
  montant: (json['montant'] as num).toInt(),
  telephone: json['telephone'] as String?,
  reference: json['reference'] as String?,
  message: json['message'] as String?,
);

Map<String, dynamic> _$PaymentDtoToJson(PaymentDto instance) =>
    <String, dynamic>{
      'methode': instance.methode,
      'statut': instance.statut,
      'montant': instance.montant,
      'telephone': instance.telephone,
      'reference': instance.reference,
      'message': instance.message,
    };

DriverPositionDto _$DriverPositionDtoFromJson(Map<String, dynamic> json) =>
    DriverPositionDto(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      majLe: json['maj_le'] == null
          ? null
          : DateTime.parse(json['maj_le'] as String),
    );

Map<String, dynamic> _$DriverPositionDtoToJson(DriverPositionDto instance) =>
    <String, dynamic>{
      'lat': instance.lat,
      'lng': instance.lng,
      'maj_le': instance.majLe?.toIso8601String(),
    };

BookingDto _$BookingDtoFromJson(Map<String, dynamic> json) => BookingDto(
  id: (json['id'] as num).toInt(),
  trajet: TripDto.fromJson(json['trajet'] as Map<String, dynamic>),
  nbPlaces: (json['nb_places'] as num).toInt(),
  statut: json['statut'] as String,
  prixTotal: (json['prix_total'] as num).toInt(),
  paiement: PaymentDto.fromJson(json['paiement'] as Map<String, dynamic>),
  creeLe: DateTime.parse(json['cree_le'] as String),
  fraisService: (json['frais_service'] as num?)?.toInt() ?? 0,
  pointPriseEnChargeId: (json['point_prise_en_charge_id'] as num?)?.toInt(),
  codeDepart: json['code_depart'] as String?,
  annulationGratuiteJusquAu: json['annulation_gratuite_jusqu_au'] == null
      ? null
      : DateTime.parse(json['annulation_gratuite_jusqu_au'] as String),
  annulationTardive: json['annulation_tardive'] as bool? ?? false,
  conducteurTelephone: json['conducteur_telephone'] as String?,
  positionConducteur: json['position_conducteur'] == null
      ? null
      : DriverPositionDto.fromJson(
          json['position_conducteur'] as Map<String, dynamic>,
        ),
  arriveeConducteurMin: (json['arrivee_conducteur_min'] as num?)?.toInt(),
  actions:
      (json['actions'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$BookingDtoToJson(BookingDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'trajet': instance.trajet.toJson(),
      'nb_places': instance.nbPlaces,
      'statut': instance.statut,
      'prix_total': instance.prixTotal,
      'frais_service': instance.fraisService,
      'paiement': instance.paiement.toJson(),
      'cree_le': instance.creeLe.toIso8601String(),
      'point_prise_en_charge_id': instance.pointPriseEnChargeId,
      'code_depart': instance.codeDepart,
      'annulation_gratuite_jusqu_au': instance.annulationGratuiteJusquAu
          ?.toIso8601String(),
      'annulation_tardive': instance.annulationTardive,
      'conducteur_telephone': instance.conducteurTelephone,
      'position_conducteur': instance.positionConducteur?.toJson(),
      'arrivee_conducteur_min': instance.arriveeConducteurMin,
      'actions': instance.actions,
    };
