import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kovoit/core/utils/clock.dart';
import 'package:kovoit/features/search/presentation/providers/search_providers.dart';
import 'package:kovoit/features/search/domain/repositories/search_repository.dart';
import 'package:kovoit/features/trip/domain/entities/geo_place.dart';
import 'package:kovoit/features/vehicle/domain/entities/vehicle.dart';

const _a = GeoPlace(id: 'lieu-1', libelle: 'Carrefour Franciscain', quartier: 'Adidogomé', lat: 6.166, lng: 1.165);
const _b = GeoPlace(id: 'lieu-4', libelle: 'Université de Lomé', quartier: 'Tokoin', lat: 6.168, lng: 1.214);

void main() {
  late ProviderContainer container;
  late DateTime now;

  setUp(() {
    now = DateTime.utc(2026, 10, 8, 7, 20);
    container = ProviderContainer(overrides: [clockProvider.overrideWithValue(() => now)]);
    addTearDown(container.dispose);
  });

  SearchFormController form() => container.read(searchFormProvider.notifier);
  SearchForm state() => container.read(searchFormProvider);

  test('heure par défaut : prochain quart d’heure, en heure de Lomé', () {
    expect(state().dateTime, DateTime.utc(2026, 10, 8, 7, 30));
  });

  test('départ et destination obligatoires', () {
    expect(form().submit(), isNull);
    expect(state().errors.keys, containsAll([SearchFormField.depart, SearchFormField.arrivee]));
  });

  test('destination identique au départ refusée', () {
    form()
      ..setDepart(_a)
      ..setArrivee(_a);
    expect(form().submit(), isNull);
    expect(state().errors[SearchFormField.arrivee], contains('différente'));
  });

  test('heure passée refusée', () {
    form()
      ..setDepart(_a)
      ..setArrivee(_b)
      ..setTime(6, 0);
    expect(form().submit(), isNull);
    expect(state().errors.keys, [SearchFormField.dateTime]);
  });

  test('l’erreur disparaît quand on corrige', () {
    form().submit();
    form().setDepart(_a);
    expect(state().errors.containsKey(SearchFormField.depart), isFalse);
  });

  test('formulaire valide → requête', () {
    form()
      ..setDepart(_a)
      ..setArrivee(_b);
    final query = form().submit()!;
    expect(query.arrivee, _b);
    expect(query.dateTime, DateTime.utc(2026, 10, 8, 7, 30));
  });

  test('inverser départ et destination', () {
    form()
      ..setDepart(_a)
      ..setArrivee(_b)
      ..swapPlaces();
    expect(state().depart, _b);
    expect(state().arrivee, _a);
  });

  group('CA-055-2 : filtre Moto / Voiture', () {
    test('« Tous » par défaut sur un formulaire neuf', () {
      expect(state().vehicleType, isNull);
      form()
        ..setDepart(_a)
        ..setArrivee(_b);
      expect(form().submit()!.vehicleType, isNull);
    });

    test('le type choisi part dans la requête, et « Tous » se remet', () {
      form()
        ..setDepart(_a)
        ..setArrivee(_b)
        ..setVehicleType(VehicleType.moto);
      expect(form().submit()!.vehicleType, VehicleType.moto);
      form().setVehicleType(null);
      expect(form().submit()!.vehicleType, isNull);
    });

    test('le type est conservé en modifiant les lieux, la date ou l’heure', () {
      form()
        ..setVehicleType(VehicleType.voiture)
        ..setDepart(_a)
        ..setArrivee(_b)
        ..setTime(8, 0);
      expect(state().vehicleType, VehicleType.voiture);
    });

    test('le type est conservé après l’échange départ / destination', () {
      form()
        ..setDepart(_a)
        ..setArrivee(_b)
        ..setVehicleType(VehicleType.moto)
        ..swapPlaces();
      expect(state().vehicleType, VehicleType.moto);
    });

    test('le type est conservé en reprenant une recherche récente', () {
      form()
        ..setVehicleType(VehicleType.moto)
        ..applyRecent(const RecentSearch(depart: _b, arrivee: _a));
      expect(state().depart, _b);
      expect(state().vehicleType, VehicleType.moto);
    });
  });
}
