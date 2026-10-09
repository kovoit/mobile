import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../trip/data/dto/trip_dto.dart';
import '../../domain/repositories/search_repository.dart';

/// Recherches récentes dans `SharedPreferences` : seulement des lieux publics, rien de sensible.
class RecentSearchRepositoryImpl implements RecentSearchRepository {
  RecentSearchRepositoryImpl(this._prefs);

  final SharedPreferencesAsync _prefs;

  static const _key = 'kovoit_recent_searches';
  static const int maxItems = 3;

  @override
  Future<List<RecentSearch>> load() async {
    final raw = await _prefs.getString(_key);
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final item in list.cast<Map<String, dynamic>>())
          RecentSearch(
            depart: GeoPlaceDto.fromJson(item['depart'] as Map<String, dynamic>).toEntity(),
            arrivee: GeoPlaceDto.fromJson(item['arrivee'] as Map<String, dynamic>).toEntity(),
            vehicleTypeApi: item['type'] as String? ?? 'voiture',
          ),
      ];
    } on Object {
      // Donnée corrompue ou ancien format : on repart de zéro.
      await _prefs.remove(_key);
      return const [];
    }
  }

  @override
  Future<List<RecentSearch>> remember(RecentSearch search) async {
    bool same(RecentSearch r) =>
        r.depart == search.depart && r.arrivee == search.arrivee && r.vehicleTypeApi == search.vehicleTypeApi;
    final updated = [search, ...(await load()).where((r) => !same(r))].take(maxItems).toList();
    await _prefs.setString(
      _key,
      jsonEncode([
        for (final r in updated)
          {
            'depart': GeoPlaceDto.fromEntity(r.depart).toJson(),
            'arrivee': GeoPlaceDto.fromEntity(r.arrivee).toJson(),
            'type': r.vehicleTypeApi,
          },
      ]),
    );
    return updated;
  }
}
