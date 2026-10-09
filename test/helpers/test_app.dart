import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kovoit/app.dart';
import 'package:kovoit/core/mock/fake_backend.dart';
import 'package:kovoit/core/storage/token_storage.dart';
import 'package:kovoit/features/auth/data/services/google_auth_service.dart';
import 'package:kovoit/features/auth/presentation/providers/auth_providers.dart';
import 'package:kovoit/features/kyc/data/services/document_capture_service.dart';
import 'package:kovoit/features/kyc/presentation/providers/kyc_providers.dart';

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
    backend = FakeBackend(storage, latency: Duration.zero);
  }

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
  final FakeCaptureService camera = FakeCaptureService();

  List<Override> get overrides => [
        tokenStorageProvider.overrideWithValue(storage),
        fakeBackendProvider.overrideWithValue(backend),
        googleAuthServiceProvider.overrideWithValue(FakeGoogleAuthService()),
        documentCaptureServiceProvider.overrideWithValue(camera),
        splashMinDurationProvider.overrideWithValue(Duration.zero),
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
