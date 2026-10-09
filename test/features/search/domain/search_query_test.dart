import 'package:flutter_test/flutter_test.dart';
import 'package:kovoit/features/search/domain/entities/search_query.dart';
import 'package:kovoit/features/trip/domain/entities/geo_place.dart';
import 'package:kovoit/features/vehicle/domain/entities/vehicle.dart';

const _franciscain = GeoPlace(
  id: 1,
  libelle: 'Carrefour Franciscain',
  quartier: 'Adidogomé',
  type: GeoPlaceType.carrefour,
  lat: 6.166,
  lng: 1.165,
);

const _universite = GeoPlace(
  id: 4,
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
      places: 2,
      vehicleType: VehicleType.moto,
    );
    final uri = Uri(path: '/accueil/resultats', queryParameters: query.toQueryParameters());

    final parsed = SearchQuery.fromQueryParameters(Uri.parse(uri.toString()).queryParameters)!;

    expect(parsed.depart.libelle, 'Carrefour Franciscain');
    expect(parsed.depart.type, GeoPlaceType.carrefour);
    expect(parsed.arrivee.quartier, 'Tokoin');
    expect(parsed.dateTime, DateTime.utc(2026, 10, 8, 7, 30));
    expect(parsed.places, 2);
    expect(parsed.vehicleType, VehicleType.moto);
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
