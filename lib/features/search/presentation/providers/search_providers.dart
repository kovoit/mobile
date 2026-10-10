import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/config/env.dart';
import '../../../../core/mock/fake_backend.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/clock.dart';
import '../../../../core/utils/lome_time.dart';
import '../../../trip/domain/entities/geo_place.dart';
import '../../../vehicle/domain/entities/vehicle.dart';
import '../../data/datasources/search_remote_data_source.dart';
import '../../data/repositories/recent_search_repository_impl.dart';
import '../../data/repositories/search_repository_impl.dart';
import '../../domain/entities/search_query.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/repositories/search_repository.dart';

final searchRemoteDataSourceProvider = Provider<SearchRemoteDataSource>((ref) {
  if (Env.useMockApi) return FakeSearchRemoteDataSource(ref.watch(fakeBackendProvider));
  return DioSearchRemoteDataSource(ref.watch(dioProvider));
});

final searchRepositoryProvider =
    Provider<SearchRepository>((ref) => SearchRepositoryImpl(ref.watch(searchRemoteDataSourceProvider)));

final recentSearchRepositoryProvider =
    Provider<RecentSearchRepository>((ref) => RecentSearchRepositoryImpl(SharedPreferencesAsync()));

/// Lieux connus pour une saisie (écran de choix du lieu).
final placeSuggestionsProvider = FutureProvider.autoDispose.family<List<GeoPlace>, String>(
  (ref, query) => ref.watch(searchRepositoryProvider).searchPlaces(query),
);

/// Résultats d'une recherche (clé : la requête, égalité de valeur).
final searchResultsProvider = FutureProvider.autoDispose.family<SearchResult, SearchQuery>(
  (ref, query) => ref.watch(searchRepositoryProvider).search(query),
);

// ------------------------------------------------------------------ Formulaire

enum SearchFormField { depart, arrivee, dateTime }

/// Brouillon du formulaire « Rechercher un trajet ». Conservé tant que l'app est ouverte,
/// pour retrouver ses critères en revenant des résultats.
class SearchForm {
  const SearchForm({
    required this.dateTime,
    this.depart,
    this.arrivee,
    this.places = 1,
    this.vehicleType = VehicleType.voiture,
    this.errors = const {},
  });

  final GeoPlace? depart;
  final GeoPlace? arrivee;
  final DateTime dateTime;
  final int places;
  final VehicleType vehicleType;
  final Map<SearchFormField, String> errors;

  /// Bornes d'interface du sélecteur de places (le backend valide les vraies limites).
  int get maxPlaces => vehicleType == VehicleType.moto ? 1 : 4;

  SearchForm copyWith({
    GeoPlace? depart,
    GeoPlace? arrivee,
    DateTime? dateTime,
    int? places,
    VehicleType? vehicleType,
    Map<SearchFormField, String>? errors,
  }) =>
      SearchForm(
        depart: depart ?? this.depart,
        arrivee: arrivee ?? this.arrivee,
        dateTime: dateTime ?? this.dateTime,
        places: places ?? this.places,
        vehicleType: vehicleType ?? this.vehicleType,
        errors: errors ?? this.errors,
      );
}

/// Les dates du formulaire sont en **heure de Lomé**, représentée en UTC (Lomé = UTC+0 toute l'année),
/// quel que soit le fuseau réglé sur le téléphone.
class SearchFormController extends Notifier<SearchForm> {
  DateTime _now() => ref.read(clockProvider)().toUtc();

  @override
  SearchForm build() => SearchForm(dateTime: LomeTime.nextQuarterHour(_now()));

  Map<SearchFormField, String> _without(SearchFormField field) => {...state.errors}..remove(field);

  void setDepart(GeoPlace place) => state = state.copyWith(depart: place, errors: _without(SearchFormField.depart));

  void setArrivee(GeoPlace place) => state = state.copyWith(arrivee: place, errors: _without(SearchFormField.arrivee));

  void setDate(DateTime date) => state = state.copyWith(
        dateTime: LomeTime.withDate(state.dateTime, date),
        errors: _without(SearchFormField.dateTime),
      );

  void setTime(int hour, int minute) => state = state.copyWith(
        dateTime: LomeTime.withTime(state.dateTime, hour, minute),
        errors: _without(SearchFormField.dateTime),
      );

  void setPlaces(int places) => state = state.copyWith(places: places.clamp(1, state.maxPlaces));

  void setVehicleType(VehicleType type) {
    final updated = state.copyWith(vehicleType: type);
    state = updated.copyWith(places: updated.places.clamp(1, updated.maxPlaces));
  }

  void swapPlaces() {
    if (state.depart == null && state.arrivee == null) return;
    state = SearchForm(
      depart: state.arrivee,
      arrivee: state.depart,
      dateTime: state.dateTime,
      places: state.places,
      vehicleType: state.vehicleType,
    );
  }

  /// Reprend une recherche récente (lieux et type de véhicule ; l'heure reste celle choisie).
  void applyRecent(RecentSearch recent) {
    final form = SearchForm(
      depart: recent.depart,
      arrivee: recent.arrivee,
      dateTime: state.dateTime,
      places: state.places,
      vehicleType: VehicleType.fromApi(recent.vehicleTypeApi),
    );
    state = form.copyWith(places: form.places.clamp(1, form.maxPlaces));
  }

  /// Valide le formulaire (contrôles de saisie uniquement) et renvoie la requête, ou `null`.
  SearchQuery? submit() {
    final errors = <SearchFormField, String>{
      if (state.depart == null) SearchFormField.depart: 'Choisissez un point de départ.',
      if (state.arrivee == null) SearchFormField.arrivee: 'Choisissez une destination.',
      if (state.depart != null && state.depart == state.arrivee)
        SearchFormField.arrivee: 'La destination doit être différente du départ.',
      if (state.dateTime.isBefore(_now().subtract(const Duration(minutes: 5))))
        SearchFormField.dateTime: 'Choisissez une date et une heure à venir.',
    };
    state = state.copyWith(errors: errors);
    if (errors.isNotEmpty) return null;
    return SearchQuery(
      depart: state.depart!,
      arrivee: state.arrivee!,
      dateTime: state.dateTime,
      places: state.places,
      vehicleType: state.vehicleType,
    );
  }
}

final searchFormProvider = NotifierProvider<SearchFormController, SearchForm>(SearchFormController.new);

/// Recherches récentes (« Votre trajet du quotidien »).
class RecentSearchesController extends AsyncNotifier<List<RecentSearch>> {
  @override
  Future<List<RecentSearch>> build() => ref.read(recentSearchRepositoryProvider).load();

  Future<void> remember(SearchQuery query) async {
    state = AsyncData(
      await ref.read(recentSearchRepositoryProvider).remember(
            RecentSearch(depart: query.depart, arrivee: query.arrivee, vehicleTypeApi: query.vehicleType.apiValue),
          ),
    );
  }
}

final recentSearchesProvider =
    AsyncNotifierProvider<RecentSearchesController, List<RecentSearch>>(RecentSearchesController.new);
