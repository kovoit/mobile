import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env.dart';
import '../../../../core/mock/fake_driver.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/clock.dart';
import '../../../../core/utils/lome_time.dart';
import '../../../auth/presentation/providers/session_controller.dart';
import '../../../trip/domain/entities/geo_place.dart';
import '../../../vehicle/domain/entities/vehicle.dart';
import '../../data/datasources/driver_remote_data_source.dart';
import '../../data/repositories/driver_repository_impl.dart';
import '../../domain/entities/driver_trip.dart';
import '../../domain/repositories/driver_repository.dart';

final driverRemoteDataSourceProvider = Provider<DriverRemoteDataSource>((ref) {
  if (Env.useMockApi) return FakeDriverRemoteDataSource(ref.watch(fakeDriverProvider));
  return DioDriverRemoteDataSource(ref.watch(dioProvider));
});

final driverRepositoryProvider =
    Provider<DriverRepository>((ref) => DriverRepositoryImpl(ref.watch(driverRemoteDataSourceProvider)));

/// Économies du mois en cours (bloc sombre de l'Espace Conducteur).
final driverSavingsProvider = FutureProvider.autoDispose<DriverSavings>((ref) {
  ref.watch(sessionControllerProvider.select((s) => s.value?.id));
  return ref.watch(driverRepositoryProvider).savings();
});

// ------------------------------------------------------------------ Trajets publiés

class MyDriverTripsController extends AsyncNotifier<List<DriverTrip>> {
  @override
  Future<List<DriverTrip>> build() {
    ref.watch(sessionControllerProvider.select((s) => (s.value?.id, s.value?.isDriverMode)));
    final user = ref.read(sessionControllerProvider).value;
    if (user == null || !user.isDriverMode) return Future.value(const []);
    return ref.read(driverRepositoryProvider).myTrips();
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() => ref.read(driverRepositoryProvider).myTrips());
  }

  void upsert(DriverTrip trip) {
    final current = state.value ?? const <DriverTrip>[];
    final exists = current.any((t) => t.id == trip.id);
    state = AsyncData(exists ? [for (final t in current) t.id == trip.id ? trip : t] : [...current, trip]);
  }
}

final myDriverTripsProvider =
    AsyncNotifierProvider<MyDriverTripsController, List<DriverTrip>>(MyDriverTripsController.new);

/// Un trajet publié et ses demandes (écran de gestion du trajet).
class DriverTripController extends AsyncNotifier<DriverTrip> {
  DriverTripController(this.tripId);

  final int tripId;

  DriverRepository get _repository => ref.read(driverRepositoryProvider);

  @override
  Future<DriverTrip> build() => _repository.trip(tripId);

  void _set(DriverTrip trip) {
    state = AsyncData(trip);
    ref.read(myDriverTripsProvider.notifier).upsert(trip);
  }

  /// Relecture silencieuse (sondage, après une action) : en cas d'erreur, on garde l'affichage.
  Future<void> refresh() async {
    try {
      _set(await _repository.trip(tripId));
    } on Object {
      // Le prochain sondage réessaiera.
    }
  }

  /// Action sur une demande, puis relecture du trajet (places, statuts, actions).
  Future<void> _then(Future<void> Function() action) async {
    await action();
    _set(await _repository.trip(tripId));
  }

  Future<void> accept(int requestId) => _then(() => _repository.accept(requestId));

  Future<void> refuse(int requestId) => _then(() => _repository.refuse(requestId));

  Future<void> submitCode(int requestId, String code) =>
      _then(() => _repository.submitDepartureCode(requestId, code));

  Future<void> declareAbsence(int requestId, {required double lat, required double lng}) =>
      _then(() => _repository.declareAbsence(requestId, lat: lat, lng: lng));

  Future<void> finish() async {
    _set(await _repository.finishTrip(tripId));
    ref.invalidate(driverSavingsProvider);
  }

  Future<void> cancel() async => _set(await _repository.cancelTrip(tripId));
}

final driverTripProvider =
    AsyncNotifierProvider.autoDispose.family<DriverTripController, DriverTrip, int>(DriverTripController.new);

// ------------------------------------------------------------------ Publication

enum PublishField { depart, arrivee, pickups, dateTime, places }

/// Formulaire « Publier un trajet » (maquette « Espace Conducteur »).
class PublishForm {
  const PublishForm({
    required this.dateTime,
    this.depart,
    this.arrivee,
    this.pickups = const [],
    this.places = 1,
    this.errors = const {},
  });

  /// Nombre maximal de carrefours de prise en charge (spéc. : 1 à 3).
  static const int maxPickups = 3;

  final GeoPlace? depart;
  final GeoPlace? arrivee;
  final List<GeoPlace> pickups;
  final DateTime dateTime;
  final int places;
  final Map<PublishField, String> errors;

  bool get canAddPickup => pickups.length < maxPickups;

  PublishForm copyWith({
    GeoPlace? depart,
    GeoPlace? arrivee,
    List<GeoPlace>? pickups,
    DateTime? dateTime,
    int? places,
    Map<PublishField, String>? errors,
  }) =>
      PublishForm(
        depart: depart ?? this.depart,
        arrivee: arrivee ?? this.arrivee,
        pickups: pickups ?? this.pickups,
        dateTime: dateTime ?? this.dateTime,
        places: places ?? this.places,
        errors: errors ?? this.errors,
      );
}

class PublishFormController extends Notifier<PublishForm> {
  DateTime _now() => ref.read(clockProvider)().toUtc();

  @override
  PublishForm build() => PublishForm(dateTime: LomeTime.nextQuarterHour(_now()));

  Map<PublishField, String> _without(PublishField field) => {...state.errors}..remove(field);

  /// Le point de départ est proposé comme premier carrefour de prise en charge (modifiable).
  void setDepart(GeoPlace place) {
    final previous = state.depart;
    final pickups = [
      if (state.pickups.isEmpty || state.pickups.first == previous) place,
      ...state.pickups.where((p) => p != previous && p != place),
    ].take(PublishForm.maxPickups).toList();
    state = state.copyWith(depart: place, pickups: pickups, errors: _without(PublishField.depart));
  }

  void setArrivee(GeoPlace place) => state = state.copyWith(arrivee: place, errors: _without(PublishField.arrivee));

  void addPickup(GeoPlace place) {
    if (!state.canAddPickup || state.pickups.contains(place)) return;
    state = state.copyWith(pickups: [...state.pickups, place], errors: _without(PublishField.pickups));
  }

  void removePickup(GeoPlace place) => state = state.copyWith(pickups: [...state.pickups]..remove(place));

  void setDate(DateTime date) =>
      state = state.copyWith(dateTime: LomeTime.withDate(state.dateTime, date), errors: _without(PublishField.dateTime));

  void setTime(int hour, int minute) => state = state.copyWith(
        dateTime: LomeTime.withTime(state.dateTime, hour, minute),
        errors: _without(PublishField.dateTime),
      );

  void setPlaces(int places, {required int max}) => state = state.copyWith(places: places.clamp(1, max));

  /// Contrôles de saisie uniquement ; le backend revalide tout (places, droits, horaire).
  TripDraft? submit({required int maxPlaces}) {
    final errors = <PublishField, String>{
      if (state.depart == null) PublishField.depart: 'Choisissez votre point de départ.',
      if (state.arrivee == null) PublishField.arrivee: 'Choisissez votre destination.',
      if (state.depart != null && state.depart == state.arrivee)
        PublishField.arrivee: 'La destination doit être différente du départ.',
      if (state.pickups.isEmpty) PublishField.pickups: 'Ajoutez au moins un carrefour de prise en charge.',
      if (!state.dateTime.isAfter(_now())) PublishField.dateTime: 'Choisissez une heure de départ à venir.',
      if (state.places > maxPlaces) PublishField.places: 'Au plus $maxPlaces places pour ce véhicule.',
    };
    state = state.copyWith(errors: errors);
    if (errors.isNotEmpty) return null;
    return TripDraft(
      depart: state.depart!,
      arrivee: state.arrivee!,
      pickupPoints: state.pickups,
      departureAt: state.dateTime,
      places: state.places,
    );
  }

  /// Après une publication réussie : on garde la date, on vide le reste.
  void reset() => state = PublishForm(dateTime: state.dateTime);

  /// Erreurs par champ renvoyées par l'API (400).
  void applyServerErrors(Map<String, String> fieldErrors) {
    const mapping = {
      'points_prise_en_charge': PublishField.pickups,
      'places_total': PublishField.places,
      'depart_le': PublishField.dateTime,
      'depart': PublishField.depart,
      'arrivee': PublishField.arrivee,
    };
    state = state.copyWith(errors: {
      for (final entry in fieldErrors.entries) ?mapping[entry.key]: entry.value,
    });
  }
}

final publishFormProvider = NotifierProvider<PublishFormController, PublishForm>(PublishFormController.new);

/// Prix recommandé par le backend pour un départ, une arrivée et un type de véhicule.
final priceEstimateProvider =
    FutureProvider.autoDispose.family<PriceEstimate, (GeoPlace, GeoPlace, VehicleType)>((ref, key) {
  final (depart, arrivee, vehicleType) = key;
  return ref.watch(driverRepositoryProvider).estimatePrice(
        depart: depart,
        arrivee: arrivee,
        pickupPoints: ref.read(publishFormProvider).pickups,
        vehicleType: vehicleType,
      );
});
