import 'package:flutter_test/flutter_test.dart';
import 'package:kovoit/features/search/domain/entities/search_query.dart';
import 'package:kovoit/features/trip/domain/entities/geo_place.dart';
import 'package:kovoit/features/vehicle/domain/entities/vehicle.dart';

const _franciscain = GeoPlace(
  id: 'lieu-1',
  libelle: 'Carrefour Franciscain',
  quartier: 'Adidogomé',
  type: GeoPlaceType.carrefour,
  lat: 6.166,
  lng: 1.165,
);

const _universite = GeoPlace(
  id: 'lieu-4',
  libelle: 'Université de Lomé · Entrée sud',
  quartier: 'Tokoin',
  type: GeoPlaceType.repere,
  lat: 6.168,
  lng: 1.214,
);

void main() {
  test('les critères survivent à un aller-retour par l’URL', () {
    final query = SearchQuery(
      depart: _franciscain,
      arrivee: _universite,
      dateTime: DateTime.utc(2026, 10, 8, 7, 30),
    );
    final uri = Uri(path: '/accueil/resultats', queryParameters: query.toQueryParameters());

    final parsed = SearchQuery.fromQueryParameters(Uri.parse(uri.toString()).queryParameters)!;

    expect(parsed.depart.libelle, 'Carrefour Franciscain');
    expect(parsed.depart.type, GeoPlaceType.carrefour);
    expect(parsed.arrivee.quartier, 'Tokoin');
    expect(parsed.dateTime, DateTime.utc(2026, 10, 8, 7, 30));
  });

  group('type de véhicule (F-055)', () {
    SearchQuery query([VehicleType? type]) => SearchQuery(
          depart: _franciscain,
          arrivee: _universite,
          dateTime: DateTime.utc(2026, 10, 8, 7, 30),
          vehicleType: type,
        );
    SearchQuery roundTrip(SearchQuery q) => SearchQuery.fromQueryParameters(
          Uri.parse(Uri(path: '/accueil/resultats', queryParameters: q.toQueryParameters()).toString())
              .queryParameters,
        )!;

    test('« Moto » et « Voiture » survivent à l’aller-retour par l’URL', () {
      expect(query(VehicleType.moto).toQueryParameters()['type'], 'moto');
      expect(roundTrip(query(VehicleType.moto)).vehicleType, VehicleType.moto);
      expect(roundTrip(query(VehicleType.voiture)).vehicleType, VehicleType.voiture);
    });

    test('« Tous » : pas de paramètre dans l’URL', () {
      expect(query().toQueryParameters().containsKey('type'), isFalse);
      expect(roundTrip(query()).vehicleType, isNull);
    });

    test('valeur inconnue dans l’URL → tous les types', () {
      final params = {...query().toQueryParameters(), 'type': 'camion'};
      expect(SearchQuery.fromQueryParameters(params)!.vehicleType, isNull);
    });

    test('le type fait partie de l’égalité (clé du provider des résultats)', () {
      expect(query(VehicleType.moto), query(VehicleType.moto));
      expect(query(VehicleType.moto).hashCode, query(VehicleType.moto).hashCode);
      expect(query(VehicleType.moto), isNot(query()));
      expect(query(VehicleType.moto), isNot(query(VehicleType.voiture)));
    });
  });

  test('URL incomplète ou abîmée → null', () {
    expect(SearchQuery.fromQueryParameters({'dlib': 'X', 'dlat': 'abc'}), isNull);
  });

  test('libellés courts de la maquette', () {
    expect(_franciscain.displayName, 'Adidogomé');
    expect(_universite.displayName, 'Université de Lomé');
    expect(_franciscain.fullLabel, 'Carrefour Franciscain, Adidogomé');
    expect(_universite.fullLabel, 'Université de Lomé · Entrée sud');
  });
}
