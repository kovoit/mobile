import 'package:flutter_test/flutter_test.dart';
import 'package:kovoit/core/mock/fake_trips.dart';
import 'package:kovoit/core/network/api_exception.dart';
import 'package:kovoit/features/search/data/dto/search_response_dto.dart';
import 'package:kovoit/features/trip/data/dto/trip_dto.dart';

/// Vérifie que le backend simulé respecte le contrat du vrai backend (ResultatRechercheSerializer,
/// TrajetDetailSerializer), pour que la démo et les tests de widgets reposent sur des données cohérentes.
void main() {
  // Carrefour Franciscain (Adidogomé) → Université de Lomé.
  List<Map<String, dynamic>> search({int hour = 7, int minute = 30, double arriveeLng = 1.2140, String? type}) =>
      FakeTrips.search(
        departLat: 6.1660,
        departLng: 1.1650,
        arriveeLat: 6.1680,
        arriveeLng: arriveeLng,
        dateHeure: DateTime.utc(2026, 10, 8, hour, minute),
        typeVehicule: type,
      );

  String driverOf(Map<String, dynamic> result) => ((result['trajet'] as Map)['conducteur'] as Map)['prenom'] as String;

  test('07:30 : trajets triés par heure de départ, moto comprise (pas de filtre)', () {
    final results = search();
    expect(results.map(driverOf), ['Koffi', 'Yawo', 'Akossiwa', 'Kossi']);
    expect((results.first['trajet'] as Map)['depart_le'], '2026-10-08T07:30:00.000Z');
    expect(results.first['distance_marche_km'], 0.0);
    expect((results.first['point_propose'] as Map)['libelle'], 'Carrefour Franciscain');
  });

  group('filtre type_vehicule (contrat C2, F-055)', () {
    String typeOf(Map<String, dynamic> result) =>
        ((result['trajet'] as Map)['vehicule'] as Map)['type_vehicule'] as String;

    test('moto → seulement les motos ; voiture → seulement les voitures', () {
      expect(search(type: 'moto').map(driverOf), ['Yawo']);
      expect(search(type: 'voiture').map(driverOf), ['Koffi', 'Akossiwa', 'Kossi']);
      expect(search(type: 'voiture').map(typeOf).toSet(), {'voiture'});
    });

    test('absent ou vide → tous les types', () {
      expect(search(type: ''), hasLength(4));
      expect(search(), hasLength(4));
    });

    test('valeur inconnue (dont majuscules) → 400 DONNEES_INVALIDES sur type_vehicule', () {
      for (final value in ['camion', 'Moto']) {
        expect(
          () => search(type: value),
          throwsA(isA<BadRequestApiException>()
              .having((e) => e.code, 'code', 'DONNEES_INVALIDES')
              .having((e) => e.fieldErrors.keys, 'champs', ['type_vehicule'])),
        );
      }
    });
  });

  test('fenêtre horaire de ± 15 min', () {
    expect(search(hour: 10, minute: 0), isEmpty);
    expect(search(hour: 7, minute: 52), hasLength(2), reason: '07:40 et 07:45 restent dans la fenêtre');
  });

  test('arrivée trop éloignée : aucun résultat', () {
    expect(search(arriveeLng: 1.30), isEmpty);
  });

  test('le résultat respecte le DTO et le détail porte l’aperçu du paiement', () {
    final match = SearchMatchDto.fromJson(search().first);
    final trip = match.toEntity();
    expect(trip.id, startsWith('trajet-20261008-'));
    expect(trip.matchedPickupId, match.pointPropose.id);
    expect(trip.prixPlace, 300);

    final detail = TripDto.fromJson(FakeTrips.tripById(trip.id, soldeDisponible: 100)!).toEntity();
    expect(detail.departureAt, trip.departureAt);
    expect(detail.payment!.montantTotal, 300);
    expect(detail.payment!.complementAPayer, 200);
  });

  test('recherche de lieux sans accents', () {
    final lieux = FakeTrips.searchPlaces('universite');
    expect(lieux.single['libelle'], 'Université de Lomé · Entrée sud');
    expect(GeoPlaceDto.fromJson(lieux.single).toEntity().id, 'lieu-4');
  });
}
