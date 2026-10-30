import 'package:json_annotation/json_annotation.dart';

import '../../../vehicle/domain/entities/vehicle.dart';
import '../../domain/entities/geo_place.dart';
import '../../domain/entities/trip.dart';

part 'trip_dto.g.dart';

/// Décimal DRF (`"8.40"`) ou nombre : la distance arrive en chaîne par défaut.
double? decimalFromJson(Object? value) => switch (value) {
      num() => value.toDouble(),
      String() => double.tryParse(value),
      _ => null,
    };

/// Photo vide (`""`) ou absente : pas d'URL.
String? photoFromJson(Object? value) => value is String && value.isNotEmpty ? value : null;

/// Lieu connu de Lomé (`GET /lieux/`, backend : apps/lieux).
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class GeoPlaceDto {
  const GeoPlaceDto({required this.libelle, required this.lat, required this.lng, this.id, this.quartier, this.type});

  factory GeoPlaceDto.fromJson(Map<String, dynamic> json) => _$GeoPlaceDtoFromJson(json);

  factory GeoPlaceDto.fromEntity(GeoPlace place) => GeoPlaceDto(
        id: place.id,
        libelle: place.libelle,
        quartier: place.quartier,
        type: place.type.apiValue,
        lat: place.lat,
        lng: place.lng,
      );

  final String? id;
  final String libelle;
  final String? quartier;
  final String? type;
  final double lat;
  final double lng;

  Map<String, dynamic> toJson() => _$GeoPlaceDtoToJson(this);

  GeoPlace toEntity() => GeoPlace(
        id: id,
        libelle: libelle,
        quartier: quartier == null || quartier!.isEmpty ? null : quartier,
        type: GeoPlaceType.fromApi(type),
        lat: lat,
        lng: lng,
      );
}

/// Bloc `confiance` du profil public (backend : ConfianceSerializer).
@JsonSerializable(fieldRename: FieldRename.snake)
class TrustDto {
  const TrustDto({
    this.noteMoyenne,
    this.nombreNotes = 0,
    this.fiabilitePct = 100,
    this.passagerVerifie = false,
    this.conducteurVerifie = false,
  });

  factory TrustDto.fromJson(Map<String, dynamic> json) => _$TrustDtoFromJson(json);

  final double? noteMoyenne;
  final int nombreNotes;
  final int fiabilitePct;
  final bool passagerVerifie;
  final bool conducteurVerifie;

  Map<String, dynamic> toJson() => _$TrustDtoToJson(this);
}

/// Profil public (backend : PersonneSerializer) : jamais d'email ni de téléphone.
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class PersonDto {
  const PersonDto({required this.id, required this.prenom, required this.nom, this.photo, this.confiance = const TrustDto()});

  factory PersonDto.fromJson(Map<String, dynamic> json) => _$PersonDtoFromJson(json);

  final String id;
  final String prenom;
  final String nom;
  @JsonKey(fromJson: photoFromJson)
  final String? photo;
  final TrustDto confiance;

  Map<String, dynamic> toJson() => _$PersonDtoToJson(this);

  TripDriver toDriver() => TripDriver(
        id: id,
        prenom: prenom,
        nom: nom,
        photoUrl: photo,
        verifie: confiance.conducteurVerifie,
        note: confiance.noteMoyenne,
        fiabilite: confiance.fiabilitePct,
        nombreNotes: confiance.nombreNotes,
      );
}

/// Véhicule vu par un passager (backend : VehiculeResumeSerializer).
@JsonSerializable(fieldRename: FieldRename.snake)
class TripVehicleDto {
  const TripVehicleDto({
    required this.typeVehicule,
    required this.marque,
    required this.modele,
    required this.couleur,
    required this.immatriculation,
    this.photo,
  });

  factory TripVehicleDto.fromJson(Map<String, dynamic> json) => _$TripVehicleDtoFromJson(json);

  final String typeVehicule;
  final String marque;
  final String modele;
  final String couleur;
  final String immatriculation;
  @JsonKey(fromJson: photoFromJson)
  final String? photo;

  Map<String, dynamic> toJson() => _$TripVehicleDtoToJson(this);

  TripVehicle toEntity() => TripVehicle(
        type: VehicleType.fromApi(typeVehicule),
        marque: marque,
        modele: modele,
        couleur: couleur,
        immatriculation: immatriculation,
        photoUrl: photo,
      );
}

/// Point de prise en charge (backend : PointSerializer).
@JsonSerializable(fieldRename: FieldRename.snake)
class PickupPointDto {
  const PickupPointDto({required this.id, required this.ordre, required this.libelle, required this.lat, required this.lng});

  factory PickupPointDto.fromJson(Map<String, dynamic> json) => _$PickupPointDtoFromJson(json);

  final String id;
  final int ordre;
  final String libelle;
  final double lat;
  final double lng;

  Map<String, dynamic> toJson() => _$PickupPointDtoToJson(this);

  PickupPoint toEntity() => PickupPoint(
        id: id,
        ordre: ordre,
        place: GeoPlace(libelle: libelle, lat: lat, lng: lng, type: GeoPlaceType.carrefour),
      );
}

/// Bloc `paiement` du détail d'un trajet (backend : ApercuPaiementSerializer).
@JsonSerializable(fieldRename: FieldRename.snake)
class PaymentPreviewDto {
  const PaymentPreviewDto({
    required this.montantTotal,
    required this.soldeDisponible,
    required this.complementAPayer,
    this.rechargeSuggeree = 0,
  });

  factory PaymentPreviewDto.fromJson(Map<String, dynamic> json) => _$PaymentPreviewDtoFromJson(json);

  final int montantTotal;
  final int soldeDisponible;
  final int complementAPayer;
  final int rechargeSuggeree;

  Map<String, dynamic> toJson() => _$PaymentPreviewDtoToJson(this);

  PaymentPreview toEntity() => PaymentPreview(
        montantTotal: montantTotal,
        soldeDisponible: soldeDisponible,
        complementAPayer: complementAPayer,
        rechargeSuggeree: rechargeSuggeree,
      );
}

/// Bloc `trace` du détail d'un trajet : `{source, points: [[lat, lng], …]}`.
@JsonSerializable()
class TraceDto {
  const TraceDto({required this.source, required this.points});

  factory TraceDto.fromJson(Map<String, dynamic> json) => _$TraceDtoFromJson(json);

  /// `routage` | `estimation`.
  final String source;

  /// Paires `[lat, lng]`, du départ à l'arrivée.
  final List<List<double>> points;

  Map<String, dynamic> toJson() => _$TraceDtoToJson(this);

  /// Défense : une paire incomplète est ignorée ; moins de 2 points → pas de tracé.
  TripTrace? toEntity() {
    final pairs = [
      for (final p in points)
        if (p.length >= 2) (lat: p[0], lng: p[1]),
    ];
    return pairs.length < 2 ? null : TripTrace(source: TraceSource.fromApi(source), points: pairs);
  }
}

/// Trajet (backend : TrajetSerializer, TrajetDetailSerializer avec `paiement`).
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class TripDto {
  const TripDto({
    required this.id,
    required this.conducteur,
    required this.vehicule,
    required this.departLat,
    required this.departLng,
    required this.departLibelle,
    required this.arriveeLat,
    required this.arriveeLng,
    required this.arriveeLibelle,
    required this.points,
    required this.departLe,
    required this.placesRestantes,
    required this.prixPlace,
    this.prixPassager,
    this.placesTotal = 0,
    this.distanceKm,
    this.fraisService = 0,
    this.statut = 'publie',
    this.paiement,
    this.trace,
  });

  factory TripDto.fromJson(Map<String, dynamic> json) => _$TripDtoFromJson(json);

  final String id;
  final PersonDto conducteur;
  final TripVehicleDto vehicule;
  final double departLat;
  final double departLng;
  final String departLibelle;
  final double arriveeLat;
  final double arriveeLng;
  final String arriveeLibelle;
  final List<PickupPointDto> points;
  final DateTime departLe;
  final int placesTotal;
  final int placesRestantes;
  @JsonKey(fromJson: decimalFromJson)
  final double? distanceKm;
  final int prixPlace;

  /// Détail demandé avec point_id + arrivée : prix du passager (sa part du trajet).
  final int? prixPassager;
  final int fraisService;
  final String statut;
  final PaymentPreviewDto? paiement;

  /// Tracé de la route : détail d'un trajet seulement (absent de la recherche), `null` pour un
  /// trajet publié avant l'enregistrement des tracés.
  final TraceDto? trace;

  Map<String, dynamic> toJson() => _$TripDtoToJson(this);

  Trip toEntity() => Trip(
        id: id,
        driver: conducteur.toDriver(),
        vehicle: vehicule.toEntity(),
        depart: GeoPlace(libelle: departLibelle, lat: departLat, lng: departLng),
        arrivee: GeoPlace(libelle: arriveeLibelle, lat: arriveeLat, lng: arriveeLng),
        pickupPoints: [for (final p in points) p.toEntity()]..sort((a, b) => a.ordre.compareTo(b.ordre)),
        departureAt: departLe,
        placesRestantes: placesRestantes,
        prixPlace: prixPlace,
        prixPassager: prixPassager,
        fraisService: fraisService,
        statut: statut,
        payment: paiement?.toEntity(),
        trace: trace?.toEntity(),
      );
}
