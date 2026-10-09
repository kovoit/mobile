// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GeoPlaceDto _$GeoPlaceDtoFromJson(Map<String, dynamic> json) => GeoPlaceDto(
  libelle: json['libelle'] as String,
  lat: (json['lat'] as num).toDouble(),
  lng: (json['lng'] as num).toDouble(),
  id: (json['id'] as num?)?.toInt(),
  quartier: json['quartier'] as String?,
  type: json['type'] as String?,
);

Map<String, dynamic> _$GeoPlaceDtoToJson(GeoPlaceDto instance) =>
    <String, dynamic>{
      'id': ?instance.id,
      'libelle': instance.libelle,
      'quartier': ?instance.quartier,
      'type': ?instance.type,
      'lat': instance.lat,
      'lng': instance.lng,
    };

TripDriverDto _$TripDriverDtoFromJson(Map<String, dynamic> json) =>
    TripDriverDto(
      id: (json['id'] as num).toInt(),
      prenom: json['prenom'] as String,
      nom: json['nom'] as String,
      photo: json['photo'] as String?,
      verifie: json['verifie'] as bool? ?? false,
      note: (json['note'] as num?)?.toDouble(),
      fiabilite: (json['fiabilite'] as num?)?.toInt(),
      nbTrajets: (json['nb_trajets'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$TripDriverDtoToJson(TripDriverDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'prenom': instance.prenom,
      'nom': instance.nom,
      'photo': instance.photo,
      'verifie': instance.verifie,
      'note': instance.note,
      'fiabilite': instance.fiabilite,
      'nb_trajets': instance.nbTrajets,
    };

TripVehicleDto _$TripVehicleDtoFromJson(Map<String, dynamic> json) =>
    TripVehicleDto(
      type: json['type'] as String,
      marque: json['marque'] as String,
      modele: json['modele'] as String,
      couleur: json['couleur'] as String,
      immatriculation: json['immatriculation'] as String,
      photo: json['photo'] as String?,
    );

Map<String, dynamic> _$TripVehicleDtoToJson(TripVehicleDto instance) =>
    <String, dynamic>{
      'type': instance.type,
      'marque': instance.marque,
      'modele': instance.modele,
      'couleur': instance.couleur,
      'immatriculation': instance.immatriculation,
      'photo': instance.photo,
    };

PickupPointDto _$PickupPointDtoFromJson(Map<String, dynamic> json) =>
    PickupPointDto(
      id: (json['id'] as num).toInt(),
      ordre: (json['ordre'] as num).toInt(),
      libelle: json['libelle'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      quartier: json['quartier'] as String?,
    );

Map<String, dynamic> _$PickupPointDtoToJson(PickupPointDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ordre': instance.ordre,
      'libelle': instance.libelle,
      'quartier': instance.quartier,
      'lat': instance.lat,
      'lng': instance.lng,
    };

TripDto _$TripDtoFromJson(Map<String, dynamic> json) => TripDto(
  id: (json['id'] as num).toInt(),
  conducteur: TripDriverDto.fromJson(
    json['conducteur'] as Map<String, dynamic>,
  ),
  vehicule: TripVehicleDto.fromJson(json['vehicule'] as Map<String, dynamic>),
  depart: GeoPlaceDto.fromJson(json['depart'] as Map<String, dynamic>),
  arrivee: GeoPlaceDto.fromJson(json['arrivee'] as Map<String, dynamic>),
  pointsPriseEnCharge: (json['points_prise_en_charge'] as List<dynamic>)
      .map((e) => PickupPointDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  departLe: DateTime.parse(json['depart_le'] as String),
  placesRestantes: (json['places_restantes'] as num).toInt(),
  prixPlace: (json['prix_place'] as num).toInt(),
  fraisService: (json['frais_service'] as num?)?.toInt() ?? 0,
  prixTotal: (json['prix_total'] as num?)?.toInt(),
  arriveeEstimeeLe: json['arrivee_estimee_le'] == null
      ? null
      : DateTime.parse(json['arrivee_estimee_le'] as String),
  pointCorrespondantId: (json['point_correspondant_id'] as num?)?.toInt(),
  distanceMarcheKm: (json['distance_marche_km'] as num?)?.toDouble(),
);

Map<String, dynamic> _$TripDtoToJson(TripDto instance) => <String, dynamic>{
  'id': instance.id,
  'conducteur': instance.conducteur.toJson(),
  'vehicule': instance.vehicule.toJson(),
  'depart': instance.depart.toJson(),
  'arrivee': instance.arrivee.toJson(),
  'points_prise_en_charge': instance.pointsPriseEnCharge
      .map((e) => e.toJson())
      .toList(),
  'depart_le': instance.departLe.toIso8601String(),
  'arrivee_estimee_le': instance.arriveeEstimeeLe?.toIso8601String(),
  'places_restantes': instance.placesRestantes,
  'prix_place': instance.prixPlace,
  'frais_service': instance.fraisService,
  'prix_total': instance.prixTotal,
  'point_correspondant_id': instance.pointCorrespondantId,
  'distance_marche_km': instance.distanceMarcheKm,
};
