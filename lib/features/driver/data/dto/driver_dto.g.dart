// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PassengerSummaryDto _$PassengerSummaryDtoFromJson(Map<String, dynamic> json) =>
    PassengerSummaryDto(
      id: (json['id'] as num).toInt(),
      prenom: json['prenom'] as String,
      nom: json['nom'] as String,
      verifie: json['verifie'] as bool? ?? false,
      photo: json['photo'] as String?,
      note: (json['note'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$PassengerSummaryDtoToJson(
  PassengerSummaryDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'prenom': instance.prenom,
  'nom': instance.nom,
  'verifie': instance.verifie,
  'photo': instance.photo,
  'note': instance.note,
};

DriverRequestDto _$DriverRequestDtoFromJson(Map<String, dynamic> json) =>
    DriverRequestDto(
      id: (json['id'] as num).toInt(),
      passager: PassengerSummaryDto.fromJson(
        json['passager'] as Map<String, dynamic>,
      ),
      nbPlaces: (json['nb_places'] as num).toInt(),
      statut: json['statut'] as String,
      methodePaiement: json['methode_paiement'] as String,
      statutPaiement: json['statut_paiement'] as String,
      montant: (json['montant'] as num).toInt(),
      pointPriseEnChargeId: (json['point_prise_en_charge_id'] as num?)?.toInt(),
      actions:
          (json['actions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$DriverRequestDtoToJson(DriverRequestDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'passager': instance.passager.toJson(),
      'nb_places': instance.nbPlaces,
      'statut': instance.statut,
      'methode_paiement': instance.methodePaiement,
      'statut_paiement': instance.statutPaiement,
      'montant': instance.montant,
      'point_prise_en_charge_id': instance.pointPriseEnChargeId,
      'actions': instance.actions,
    };

DriverTripDto _$DriverTripDtoFromJson(Map<String, dynamic> json) =>
    DriverTripDto(
      id: (json['id'] as num).toInt(),
      depart: GeoPlaceDto.fromJson(json['depart'] as Map<String, dynamic>),
      arrivee: GeoPlaceDto.fromJson(json['arrivee'] as Map<String, dynamic>),
      pointsPriseEnCharge: (json['points_prise_en_charge'] as List<dynamic>)
          .map((e) => PickupPointDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      departLe: DateTime.parse(json['depart_le'] as String),
      placesTotal: (json['places_total'] as num).toInt(),
      placesRestantes: (json['places_restantes'] as num).toInt(),
      prixPlace: (json['prix_place'] as num).toInt(),
      statut: json['statut'] as String,
      economie: (json['economie'] as num?)?.toInt() ?? 0,
      demandes:
          (json['demandes'] as List<dynamic>?)
              ?.map((e) => DriverRequestDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      actions:
          (json['actions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$DriverTripDtoToJson(DriverTripDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'depart': instance.depart.toJson(),
      'arrivee': instance.arrivee.toJson(),
      'points_prise_en_charge': instance.pointsPriseEnCharge
          .map((e) => e.toJson())
          .toList(),
      'depart_le': instance.departLe.toIso8601String(),
      'places_total': instance.placesTotal,
      'places_restantes': instance.placesRestantes,
      'prix_place': instance.prixPlace,
      'statut': instance.statut,
      'economie': instance.economie,
      'demandes': instance.demandes.map((e) => e.toJson()).toList(),
      'actions': instance.actions,
    };

PriceEstimateDto _$PriceEstimateDtoFromJson(Map<String, dynamic> json) =>
    PriceEstimateDto(
      prixPlace: (json['prix_place'] as num).toInt(),
      distanceKm: (json['distance_km'] as num).toDouble(),
      dureeMin: (json['duree_min'] as num).toInt(),
    );

Map<String, dynamic> _$PriceEstimateDtoToJson(PriceEstimateDto instance) =>
    <String, dynamic>{
      'prix_place': instance.prixPlace,
      'distance_km': instance.distanceKm,
      'duree_min': instance.dureeMin,
    };

SavingsDto _$SavingsDtoFromJson(Map<String, dynamic> json) => SavingsDto(
  mois: json['mois'] as String,
  total: (json['total'] as num).toInt(),
  places: (json['places'] as num).toInt(),
);

Map<String, dynamic> _$SavingsDtoToJson(SavingsDto instance) =>
    <String, dynamic>{
      'mois': instance.mois,
      'total': instance.total,
      'places': instance.places,
    };
