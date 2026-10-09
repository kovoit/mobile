import 'package:flutter_test/flutter_test.dart';
import 'package:kovoit/core/mock/fake_trips.dart';
import 'package:kovoit/features/search/data/dto/search_response_dto.dart';

/// Vérifie que le backend simulé respecte les règles de correspondance du contrat (docs/api/trips.md),
/// pour que la démo et les tests de widgets reposent sur des données cohérentes.
void main() {
  // Carrefour Franciscain (Adidogomé) → Université de Lomé.
  Map<String, dynamic> search({int hour = 7, int minute = 30, int places = 1, String type = 'voiture', double arriveeLng = 1.2140}) =>
      FakeTrips.search(
        departLat: 6.1660,
        departLng: 1.1650,
        arriveeLat: 6.1680,
        arriveeLng: arriveeLng,
        dateHeure: DateTime.utc(2026, 10, 8, hour, minute),
        places: places,
        typeVehicule: type,
      );

  List<Map<String, dynamic>> results(Map<String, dynamic> response) =>
      (response['resultats'] as List).cast<Map<String, dynamic>>();

  test('voiture à 07:30 : 3 trajets triés par heure de départ', () {
    final trips = results(search());
    expect(trips.map((t) => (t['conducteur'] as Map)['prenom']), ['Koffi', 'Akossiwa', 'Kossi']);
    expect(trips.first['depart_le'], '2026-10-08T07:30:00.000Z');
    expect(trips.first['distance_marche_km'], 0.0);
  });

  test('filtre par type de véhicule', () {
    final motos = results(search(type: 'moto'));
    expect(motos, hasLength(1));
    expect((motos.single['vehicule'] as Map)['type'], 'moto');
  });

  test('fenêtre horaire de ± 15 min', () {
    expect(results(search(hour: 10, minute: 0)), isEmpty);
    expect(results(search(hour: 7, minute: 52)), hasLength(2), reason: '07:40 et 07:45 restent dans la fenêtre');
  });

  test('places restantes suffisantes', () {
    final trips = results(search(places: 3));
    expect(trips.map((t) => (t['conducteur'] as Map)['prenom']), ['Akossiwa']);
  });

  test('arrivée trop éloignée : aucun résultat', () {
    expect(results(search(arriveeLng: 1.30)), isEmpty);
  });

  test('la réponse respecte le DTO et le détail est retrouvable par son id', () {
    final dto = SearchResponseDto.fromJson(search());
    expect(dto.itineraire.dureeMin, greaterThan(0));
    final trip = dto.resultats.first;
    expect(trip.prixTotal, 300);

    final detail = FakeTrips.tripById(trip.id, places: 2)!;
    expect(detail['prix_total'], 600);
    expect(detail['depart_le'], trip.departLe.toIso8601String());
  });

  test('recherche de lieux sans accents', () {
    final lieux = FakeTrips.searchPlaces('universite');
    expect(lieux.single['libelle'], 'Université de Lomé · Entrée sud');
  });
}
