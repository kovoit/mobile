import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kovoit/core/config/env.dart';
import 'package:kovoit/core/mock/fake_backend.dart';
import 'package:kovoit/core/mock/fake_trips.dart';
import 'package:kovoit/core/mock/fake_wallet.dart';
import 'package:kovoit/core/network/api_exception.dart';
import 'package:kovoit/core/widgets/user_avatar.dart';
import 'package:kovoit/features/search/data/datasources/search_remote_data_source.dart';
import 'package:kovoit/features/search/data/dto/search_response_dto.dart';
import 'package:kovoit/features/search/presentation/providers/search_providers.dart';
import 'package:kovoit/features/trip/data/datasources/trip_remote_data_source.dart';
import 'package:kovoit/features/trip/data/dto/trip_dto.dart';
import 'package:kovoit/features/trip/domain/repositories/trip_repository.dart' show TripQuery;
import 'package:kovoit/features/trip/presentation/providers/trip_providers.dart';

import '../../../helpers/flows.dart';
import '../../../helpers/test_app.dart';

/// F-003 / CA-003-3, décision Q1 révisée (M-003, contrat C3) : le backend renvoie la photo du
/// conducteur en chemin **relatif** sur la recherche et le détail ; l'app la complète avec
/// l'origine de l'API avant de l'afficher.
///
/// Les photos du FakeBackend (démo de secours) restent `null` : ce test passe par des sources de
/// données dédiées qui reprennent les réponses simulées et donnent une photo relative à Koffi seul.
const _koffiPhoto = '/media/photos_profil/koffi.jpg';
const _koffiVehicle = '/media/vehicules/koffi_yaris.jpg';

/// Réponse JSON d'un trajet (`TrajetSerializer`) où Koffi Mensah a une photo relative.
Map<String, dynamic> _withKoffiPhoto(Map<String, dynamic> trajet) {
  final conducteur = Map<String, dynamic>.from(trajet['conducteur'] as Map);
  if (conducteur['prenom'] != 'Koffi' || conducteur['nom'] != 'Mensah') return trajet;
  return {
    ...trajet,
    'conducteur': {...conducteur, 'photo': _koffiPhoto},
    'vehicule': {...Map<String, dynamic>.from(trajet['vehicule'] as Map), 'photo': _koffiVehicle},
  };
}

/// `GET /trajets/recherche/` simulé, photo relative pour Koffi (même décodage DTO que l'API).
class _PhotoSearchSource implements SearchRemoteDataSource {
  _PhotoSearchSource(this._backend);

  final FakeBackend _backend;

  @override
  Future<List<GeoPlaceDto>> searchPlaces(String query) =>
      FakeSearchRemoteDataSource(_backend).searchPlaces(query);

  @override
  Future<List<SearchMatchDto>> search(SearchParams p) async {
    await _backend.currentUserId();
    final results = FakeTrips.search(
      departLat: p.departLat,
      departLng: p.departLng,
      arriveeLat: p.arriveeLat,
      arriveeLng: p.arriveeLng,
      dateHeure: p.dateHeure,
      typeVehicule: p.typeVehicule,
    );
    return [
      for (final json in results)
        SearchMatchDto.fromJson({...json, 'trajet': _withKoffiPhoto(Map<String, dynamic>.from(json['trajet'] as Map))}),
    ];
  }
}

/// `GET /trajets/{id}/` simulé, photo relative pour Koffi.
class _PhotoTripSource implements TripRemoteDataSource {
  _PhotoTripSource(this._wallet);

  final FakeWallet _wallet;

  @override
  Future<TripDto> fetchTrip(TripQuery q) async {
    final balance = await _wallet.balance();
    final json = FakeTrips.tripById(q.id, soldeDisponible: balance['disponible']!);
    if (json == null) throw const NotFoundApiException('Ce trajet n’est plus disponible.');
    return TripDto.fromJson(_withKoffiPhoto(json));
  }
}

class _DriverPhotoEnv extends TestEnv {
  _DriverPhotoEnv() : super(accessToken: 'mock-access-1'); // compte démo, KYC passager vérifié

  @override
  List<Override> get overrides => [
        ...super.overrides,
        searchRemoteDataSourceProvider.overrideWithValue(_PhotoSearchSource(backend)),
        tripRemoteDataSourceProvider.overrideWithValue(_PhotoTripSource(wallet)),
      ];
}

Finder _avatarOf(String name) => find.byWidgetPredicate((w) => w is UserAvatar && w.name == name);

/// URL réellement demandée par l'image de l'avatar (pas seulement le paramètre du widget).
String? _loadedUrl(WidgetTester tester, Finder avatar) {
  final images = find.descendant(of: avatar, matching: find.byType(Image));
  if (images.evaluate().isEmpty) return null;
  final provider = tester.widget<Image>(images.first).image;
  return provider is NetworkImage ? provider.url : null;
}

void main() {
  setUpAll(() => initializeDateFormatting('fr'));

  final origin = Uri.parse(Env.apiBaseUrl).origin;
  final expectedPhoto = '$origin$_koffiPhoto';

  testWidgets('CA-003-3 : photo relative du conducteur complétée sur sa carte dans les résultats', (tester) async {
    await pumpKovoitApp(tester, env: _DriverPhotoEnv());
    await searchFranciscainToUniversity(tester);
    expect(find.text('4 trajets disponibles'), findsOneWidget);

    final koffi = _avatarOf('Koffi Mensah');
    expect(koffi, findsOneWidget);
    final url = tester.widget<UserAvatar>(koffi).photoUrl;
    expect(url, expectedPhoto);
    expect(Uri.parse(url!).isAbsolute, isTrue);
    expect(url, isNot(contains('/api/v1')), reason: 'origine seule, sans le préfixe de l’API');
    expect(_loadedUrl(tester, koffi), expectedPhoto, reason: 'l’image demande bien l’URL complète');

    // Les autres conducteurs n'ont pas de photo : initiales, aucune image chargée.
    final akossiwa = _avatarOf('Akossiwa Amégan');
    await scrollTo(tester, akossiwa);
    expect(tester.widget<UserAvatar>(akossiwa).photoUrl, isNull);
    expect(_loadedUrl(tester, akossiwa), isNull);
    expect(find.descendant(of: akossiwa, matching: find.text('AA')), findsOneWidget);
  });

  testWidgets('CA-003-3 : photo relative du conducteur et du véhicule complétées sur « Détails & Réservation »', (
    tester,
  ) async {
    await pumpKovoitApp(tester, env: _DriverPhotoEnv());
    await openKoffiTrip(tester);
    expect(find.text('Détails & Réservation'), findsOneWidget);

    final koffi = _avatarOf('Koffi Mensah');
    await scrollTo(tester, koffi);
    expect(koffi, findsOneWidget);
    expect(tester.widget<UserAvatar>(koffi).photoUrl, expectedPhoto);
    expect(_loadedUrl(tester, koffi), expectedPhoto);

    // Même règle pour la photo du véhicule (D-17), affichée dans la carte du conducteur.
    final vehicle = find.byWidgetPredicate(
      (w) => w is Image && (w.semanticLabel ?? '').startsWith('Photo du véhicule'),
    );
    await scrollTo(tester, vehicle);
    final image = tester.widget<Image>(vehicle).image;
    expect(image, isA<NetworkImage>());
    expect((image as NetworkImage).url, '$origin$_koffiVehicle');
  });

  testWidgets('Photo injoignable (hors ligne) : l’avatar retombe sur les initiales', (tester) async {
    await pumpKovoitApp(tester, env: _DriverPhotoEnv());
    await searchFranciscainToUniversity(tester);

    // En test, toute requête d'image échoue : l'avatar de Koffi affiche « KM », sans erreur à l'écran.
    final koffi = _avatarOf('Koffi Mensah');
    expect(find.descendant(of: koffi, matching: find.text('KM')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
