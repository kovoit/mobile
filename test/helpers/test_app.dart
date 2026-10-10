import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kovoit/app.dart';
import 'package:kovoit/core/mock/fake_backend.dart';
import 'package:kovoit/core/mock/fake_bookings.dart';
import 'package:kovoit/core/mock/fake_driver.dart';
import 'package:kovoit/core/services/location_service.dart';
import 'package:kovoit/core/services/external_actions.dart';
import 'package:kovoit/core/storage/token_storage.dart';
import 'package:kovoit/core/utils/clock.dart';
import 'package:kovoit/core/widgets/map_preview.dart';
import 'package:kovoit/features/auth/data/services/google_auth_service.dart';
import 'package:kovoit/features/auth/presentation/providers/auth_providers.dart';
import 'package:kovoit/features/kyc/data/services/document_capture_service.dart';
import 'package:kovoit/features/kyc/presentation/providers/kyc_providers.dart';
import 'package:kovoit/features/search/domain/repositories/search_repository.dart';
import 'package:kovoit/features/search/presentation/providers/search_providers.dart';

/// Recherches récentes en mémoire (pas de SharedPreferences en test de widgets).
class InMemoryRecentSearches implements RecentSearchRepository {
  final List<RecentSearch> items = [];

  @override
  Future<List<RecentSearch>> load() async => List.of(items);

  @override
  Future<List<RecentSearch>> remember(RecentSearch search) async {
    items
      ..removeWhere((r) => r.depart == search.depart && r.arrivee == search.arrivee)
      ..insert(0, search);
    return List.of(items);
  }
}

/// Tuiles de carte transparentes : ni réseau ni cache disque en test.
class TransparentTileProvider extends TileProvider {
  /// PNG 1×1 transparent.
  static final Uint8List _png = Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, //
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
    0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
    0x42, 0x60, 0x82,
  ]);

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) => MemoryImage(_png);
}

/// Appels et partages capturés au lieu d'ouvrir le système.
class RecordingExternalActions implements ExternalActions {
  final List<String> calls = [];
  final List<String> shares = [];

  @override
  Future<bool> call(String phoneNumber) async {
    calls.add(phoneNumber);
    return true;
  }

  @override
  Future<void> share(String text, {String? subject}) async => shares.add(text);
}

/// Position simulée (Carrefour Franciscain par défaut).
class FakeLocationService implements LocationService {
  LocationResult result = const LocationFound(6.1660, 1.1650);
  int calls = 0;

  @override
  Future<LocationResult> currentPosition() async {
    calls++;
    return result;
  }
}

/// Heure fixe des tests : jeudi 08 octobre 2026, 07:20 à Lomé → formulaire pré-rempli à 07:30.
final DateTime kTestNow = DateTime.utc(2026, 10, 8, 7, 20);

/// Stockage de jetons en mémoire (le plugin sécurisé n'existe pas en test).
class InMemoryTokenStorage extends TokenStorage {
  InMemoryTokenStorage() : super(const FlutterSecureStorage());

  String? access;
  String? refresh;

  @override
  Future<String?> readAccessToken() async => access;

  @override
  Future<String?> readRefreshToken() async => refresh;

  @override
  Future<void> saveTokens({required String access, String? refresh}) async {
    this.access = access;
    if (refresh != null) this.refresh = refresh;
  }

  @override
  Future<void> clear() async {
    access = null;
    refresh = null;
  }
}

/// Appareil photo simulé : renvoie un chemin factice (aucun fichier réel) et trace les suppressions.
class FakeCaptureService implements DocumentCaptureService {
  final List<CaptureSource> requests = [];
  final List<String> discarded = [];

  @override
  Future<String?> capture(CaptureSource source) async {
    requests.add(source);
    return 'test/fake_piece_${requests.length}.jpg';
  }

  @override
  Future<void> discard(String path) async => discarded.add(path);
}

/// Environnement de test : backend simulé sans latence, stockage en mémoire, caméra simulée.
class TestEnv {
  TestEnv({String? accessToken}) : storage = InMemoryTokenStorage() {
    storage.access = accessToken;
    backend = FakeBackend(storage, latency: Duration.zero, clock: () => now);
    bookings = FakeBookings(backend);
    driver = FakeDriver(backend);
  }

  /// Session du conducteur de démo (Yao Agbodjan : KYC validés, Toyota Yaris 5 places, mode conducteur).
  factory TestEnv.driverSession() => TestEnv(accessToken: 'mock-access-2');

  /// Session du compte démo (Kodjo Mensah, téléphone et KYC passager vérifiés).
  factory TestEnv.demoSession() => TestEnv(accessToken: 'mock-access-1');

  /// Session d'un compte tout juste inscrit : téléphone vérifié, aucun KYC, pas de véhicule.
  factory TestEnv.newUserSession() {
    final env = TestEnv();
    final id = env.backend.createUser(
      password: 'motdepasse',
      fields: {
        'prenom': 'Afi',
        'nom': 'Amégan',
        'email': 'afi@exemple.com',
        'telephone': '+22891234567',
        'telephone_verifie': true,
      },
    );
    env.storage.access = 'mock-access-$id';
    return env;
  }

  final InMemoryTokenStorage storage;
  late final FakeBackend backend;

  /// Réservations simulées (permet de jouer le rôle du conducteur dans les tests).
  late final FakeBookings bookings;

  /// Règles conducteur simulées (trajets publiés, demandes fictives).
  late final FakeDriver driver;
  final FakeLocationService location = FakeLocationService();
  final RecordingExternalActions externalActions = RecordingExternalActions();
  final FakeCaptureService camera = FakeCaptureService();
  final InMemoryRecentSearches recentSearches = InMemoryRecentSearches();

  /// Horloge des tests, modifiable avant le lancement de l'app.
  DateTime now = kTestNow;

  List<Override> get overrides => [
        tokenStorageProvider.overrideWithValue(storage),
        fakeBackendProvider.overrideWithValue(backend),
        googleAuthServiceProvider.overrideWithValue(FakeGoogleAuthService()),
        documentCaptureServiceProvider.overrideWithValue(camera),
        splashMinDurationProvider.overrideWithValue(Duration.zero),
        recentSearchRepositoryProvider.overrideWithValue(recentSearches),
        mapTileProviderProvider.overrideWithValue(TransparentTileProvider()),
        clockProvider.overrideWithValue(() => now),
        fakeBookingsProvider.overrideWithValue(bookings),
        fakeDriverProvider.overrideWithValue(driver),
        locationServiceProvider.overrideWithValue(location),
        externalActionsProvider.overrideWithValue(externalActions),
      ];
}

/// Fait défiler la liste verticale de l'écran jusqu'à [finder] (les ListView ne construisent
/// pas les éléments hors écran), puis tape dessus.
Future<void> scrollAndTap(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    final verticalList = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down);
    await tester.scrollUntilVisible(finder, 150, scrollable: verticalList.first);
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<TestEnv> pumpKovoitApp(WidgetTester tester, {TestEnv? env}) async {
  final testEnv = env ?? TestEnv();
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(overrides: testEnv.overrides, child: const KovoitApp()));
  await tester.pumpAndSettle();
  return testEnv;
}
