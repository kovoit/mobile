// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GeoPlaceDto _$GeoPlaceDtoFromJson(Map<String, dynamic> json) => GeoPlaceDto(
  libelle: json['libelle'] as String,
  lat: (json['lat'] as num).toDouble(),
  lng: (json['lng'] as num).toDouble(),
  id: json['id'] as String?,
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

TrustDto _$TrustDtoFromJson(Map<String, dynamic> json) => TrustDto(
  noteMoyenne: (json['note_moyenne'] as num?)?.toDouble(),
  nombreNotes: (json['nombre_notes'] as num?)?.toInt() ?? 0,
  fiabilitePct: (json['fiabilite_pct'] as num?)?.toInt() ?? 100,
  passagerVerifie: json['passager_verifie'] as bool? ?? false,
  conducteurVerifie: json['conducteur_verifie'] as bool? ?? false,
);

Map<String, dynamic> _$TrustDtoToJson(TrustDto instance) => <String, dynamic>{
  'note_moyenne': instance.noteMoyenne,
  'nombre_notes': instance.nombreNotes,
  'fiabilite_pct': instance.fiabilitePct,
  'passager_verifie': instance.passagerVerifie,
  'conducteur_verifie': instance.conducteurVerifie,
};

PersonDto _$PersonDtoFromJson(Map<String, dynamic> json) => PersonDto(
  id: json['id'] as String,
  prenom: json['prenom'] as String,
  nom: json['nom'] as String,
  photo: photoFromJson(json['photo']),
  confiance: json['confiance'] == null
      ? const TrustDto()
      : TrustDto.fromJson(json['confiance'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PersonDtoToJson(PersonDto instance) => <String, dynamic>{
  'id': instance.id,
  'prenom': instance.prenom,
  'nom': instance.nom,
  'photo': instance.photo,
  'confiance': instance.confiance.toJson(),
};

TripVehicleDto _$TripVehicleDtoFromJson(Map<String, dynamic> json) =>
    TripVehicleDto(
      typeVehicule: json['type_vehicule'] as String,
      marque: json['marque'] as String,
      modele: json['modele'] as String,
      couleur: json['couleur'] as String,
      immatriculation: json['immatriculation'] as String,
      photo: photoFromJson(json['photo']),
    );

Map<String, dynamic> _$TripVehicleDtoToJson(TripVehicleDto instance) =>
    <String, dynamic>{
      'type_vehicule': instance.typeVehicule,
      'marque': instance.marque,
      'modele': instance.modele,
      'couleur': instance.couleur,
      'immatriculation': instance.immatriculation,
      'photo': instance.photo,
    };

PickupPointDto _$PickupPointDtoFromJson(Map<String, dynamic> json) =>
    PickupPointDto(
      id: json['id'] as String,
      ordre: (json['ordre'] as num).toInt(),
      libelle: json['libelle'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );

Map<String, dynamic> _$PickupPointDtoToJson(PickupPointDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ordre': instance.ordre,
      'libelle': instance.libelle,
      'lat': instance.lat,
      'lng': instance.lng,
    };

PaymentPreviewDto _$PaymentPreviewDtoFromJson(Map<String, dynamic> json) =>
    PaymentPreviewDto(
      montantTotal: (json['montant_total'] as num).toInt(),
      soldeDisponible: (json['solde_disponible'] as num).toInt(),
      complementAPayer: (json['complement_a_payer'] as num).toInt(),
      rechargeSuggeree: (json['recharge_suggeree'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$PaymentPreviewDtoToJson(PaymentPreviewDto instance) =>
    <String, dynamic>{
      'montant_total': instance.montantTotal,
      'solde_disponible': instance.soldeDisponible,
      'complement_a_payer': instance.complementAPayer,
      'recharge_suggeree': instance.rechargeSuggeree,
    };

TraceDto _$TraceDtoFromJson(Map<String, dynamic> json) => TraceDto(
  source: json['source'] as String,
  points: (json['points'] as List<dynamic>)
      .map(
        (e) => (e as List<dynamic>).map((e) => (e as num).toDouble()).toList(),
      )
      .toList(),
);

Map<String, dynamic> _$TraceDtoToJson(TraceDto instance) => <String, dynamic>{
  'source': instance.source,
  'points': instance.points,
};

TripDto _$TripDtoFromJson(Map<String, dynamic> json) => TripDto(
  id: json['id'] as String,
  conducteur: PersonDto.fromJson(json['conducteur'] as Map<String, dynamic>),
  vehicule: TripVehicleDto.fromJson(json['vehicule'] as Map<String, dynamic>),
  departLat: (json['depart_lat'] as num).toDouble(),
  departLng: (json['depart_lng'] as num).toDouble(),
  departLibelle: json['depart_libelle'] as String,
  arriveeLat: (json['arrivee_lat'] as num).toDouble(),
  arriveeLng: (json['arrivee_lng'] as num).toDouble(),
  arriveeLibelle: json['arrivee_libelle'] as String,
  points: (json['points'] as List<dynamic>)
      .map((e) => PickupPointDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  departLe: DateTime.parse(json['depart_le'] as String),
  placesRestantes: (json['places_restantes'] as num).toInt(),
  prixPlace: (json['prix_place'] as num).toInt(),
  prixPassager: (json['prix_passager'] as num?)?.toInt(),
  placesTotal: (json['places_total'] as num?)?.toInt() ?? 0,
  distanceKm: decimalFromJson(json['distance_km']),
  fraisService: (json['frais_service'] as num?)?.toInt() ?? 0,
  statut: json['statut'] as String? ?? 'publie',
  paiement: json['paiement'] == null
      ? null
      : PaymentPreviewDto.fromJson(json['paiement'] as Map<String, dynamic>),
  trace: json['trace'] == null
      ? null
      : TraceDto.fromJson(json['trace'] as Map<String, dynamic>),
);

Map<String, dynamic> _$TripDtoToJson(TripDto instance) => <String, dynamic>{
  'id': instance.id,
  'conducteur': instance.conducteur.toJson(),
  'vehicule': instance.vehicule.toJson(),
  'depart_lat': instance.departLat,
  'depart_lng': instance.departLng,
  'depart_libelle': instance.departLibelle,
  'arrivee_lat': instance.arriveeLat,
  'arrivee_lng': instance.arriveeLng,
  'arrivee_libelle': instance.arriveeLibelle,
  'points': instance.points.map((e) => e.toJson()).toList(),
  'depart_le': instance.departLe.toIso8601String(),
  'places_total': instance.placesTotal,
  'places_restantes': instance.placesRestantes,
  'distance_km': instance.distanceKm,
  'prix_place': instance.prixPlace,
  'prix_passager': instance.prixPassager,
  'frais_service': instance.fraisService,
  'statut': instance.statut,
  'paiement': instance.paiement?.toJson(),
  'trace': instance.trace?.toJson(),
};
