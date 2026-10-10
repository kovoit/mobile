import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kovoit/core/utils/clock.dart';
import 'package:kovoit/features/driver/presentation/providers/driver_providers.dart';
import 'package:kovoit/features/trip/domain/entities/geo_place.dart';

const _a = GeoPlace(id: 1, libelle: 'Carrefour Franciscain', quartier: 'Adidogomé', lat: 6.166, lng: 1.165);
const _b = GeoPlace(id: 2, libelle: 'Carrefour Avedji', quartier: 'Avedji', lat: 6.169, lng: 1.184);
const _c = GeoPlace(id: 3, libelle: 'Carrefour Totsi', quartier: 'Totsi', lat: 6.178, lng: 1.198);
const _d = GeoPlace(id: 4, libelle: 'Université de Lomé', quartier: 'Tokoin', lat: 6.168, lng: 1.214);

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(overrides: [clockProvider.overrideWithValue(() => DateTime.utc(2026, 10, 8, 7, 20))]);
    addTearDown(container.dispose);
  });

  PublishFormController form() => container.read(publishFormProvider.notifier);
  PublishForm state() => container.read(publishFormProvider);

  test('le départ est proposé comme premier carrefour, et remplacé s’il change', () {
    form().setDepart(_a);
    expect(state().pickups, [_a]);

    form()
      ..addPickup(_b)
      ..setDepart(_c);
    expect(state().pickups, [_c, _b]);
  });

  test('3 carrefours au maximum, sans doublon', () {
    form()
      ..setDepart(_a)
      ..addPickup(_b)
      ..addPickup(_b)
      ..addPickup(_c)
      ..addPickup(_d);
    expect(state().pickups, [_a, _b, _c]);
    expect(state().canAddPickup, isFalse);
  });

  test('contrôles de saisie avant publication', () {
    form().removePickup(_a);
    expect(form().submit(maxPlaces: 4), isNull);
    expect(state().errors.keys, containsAll([PublishField.depart, PublishField.arrivee, PublishField.pickups]));

    form()
      ..setDepart(_a)
      ..setArrivee(_d)
      ..setTime(7, 0);
    expect(form().submit(maxPlaces: 4), isNull);
    expect(state().errors.keys, [PublishField.dateTime]);
  });

  test('places bornées par le véhicule, puis brouillon valide', () {
    form()
      ..setDepart(_a)
      ..setArrivee(_d)
      ..setPlaces(9, max: 4);
    expect(state().places, 4);

    final draft = form().submit(maxPlaces: 4)!;
    expect(draft.pickupPoints, [_a]);
    expect(draft.departureAt, DateTime.utc(2026, 10, 8, 7, 30));
  });

  test('erreurs du serveur reportées sur les champs', () {
    form().applyServerErrors({'places_total': 'Entre 1 et 4 places.', 'inconnu': 'x'});
    expect(state().errors, {PublishField.places: 'Entre 1 et 4 places.'});
  });
}
