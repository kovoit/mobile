import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kovoit/app.dart';
import 'package:kovoit/core/storage/token_storage.dart';
import 'package:kovoit/features/auth/data/datasources/fake_auth_remote_data_source.dart';
import 'package:kovoit/features/auth/data/services/google_auth_service.dart';
import 'package:kovoit/features/auth/presentation/providers/auth_providers.dart';

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

/// Surcharges communes : API simulée sans latence, Splash instantané, stockage en mémoire.
List<Override> testOverrides({InMemoryTokenStorage? storage}) {
  final tokens = storage ?? InMemoryTokenStorage();
  return [
    tokenStorageProvider.overrideWithValue(tokens),
    authRemoteDataSourceProvider.overrideWithValue(FakeAuthRemoteDataSource(tokens, latency: Duration.zero)),
    googleAuthServiceProvider.overrideWithValue(FakeGoogleAuthService()),
    splashMinDurationProvider.overrideWithValue(Duration.zero),
  ];
}

Future<void> pumpKovoitApp(WidgetTester tester, {InMemoryTokenStorage? storage}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(overrides: testOverrides(storage: storage), child: const KovoitApp()));
  await tester.pumpAndSettle();
}
