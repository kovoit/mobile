import 'package:flutter_test/flutter_test.dart';
import 'package:kovoit/core/mock/fake_trips.dart';
import 'package:kovoit/features/search/data/dto/search_response_dto.dart';

/// Le prix affiché est celui du passager (sa part du trajet), renvoyé par le backend.
void main() {
  Map<String, dynamic> resultat({int? prixPassager}) {
    final json = Map<String, dynamic>.from(FakeTrips.search(
      departLat: 6.1660,
      departLng: 1.1650,
      arriveeLat: 6.1680,
      arriveeLng: 1.2140,
      dateHeure: DateTime.utc(2026, 10, 8, 7, 30),
    ).first);
    if (prixPassager != null) json['prix_passager'] = prixPassager;
    return json;
  }

  test('part du trajet : prix réduit, prix complet conservé pour l’affichage', () {
    final trip = SearchMatchDto.fromJson(resultat(prixPassager: 150)).toEntity();

    expect(trip.prixPassager, 150);
    expect(trip.prixPlace, greaterThan(150));
    expect(trip.partialTrip, isTrue);
  });

  test('trajet complet ou ancien backend sans prix_passager : prix de la place', () {
    final json = resultat()..remove('prix_passager');
    final trip = SearchMatchDto.fromJson(json).toEntity();

    expect(trip.prixPassager, trip.prixPlace);
    expect(trip.partialTrip, isFalse);
  });
}
