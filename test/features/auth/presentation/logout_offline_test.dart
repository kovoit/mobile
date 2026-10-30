import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kovoit/core/network/api_exception.dart';
import 'package:kovoit/features/auth/data/datasources/fake_auth_remote_data_source.dart';
import 'package:kovoit/features/auth/data/dto/profil_dto.dart';
import 'package:kovoit/features/auth/presentation/providers/auth_providers.dart';

import '../../../helpers/test_app.dart';

const _loginTitle = 'Connectez-vous pour commencer votre trajet';
const _home = 'Le même chemin, à plusieurs. Et moins cher.';

/// API d'authentification simulée hors ligne pour `POST /auth/deconnexion/` ; compte les `GET /moi/`.
class _OfflineLogoutRemote extends FakeAuthRemoteDataSource {
  _OfflineLogoutRemote(super.backend);

  final List<String> logouts = [];
  int meCalls = 0;

  @override
  Future<void> logout(String refreshToken) async {
    logouts.add(refreshToken);
    throw const NetworkApiException();
  }

  @override
  Future<ProfilDto> me() {
    meCalls++;
    return super.me();
  }
}

/// CA-074-2 : la déconnexion réussit localement même sans réseau, et la session ne revient pas
/// au relancement de l'app.
void main() {
  setUpAll(() => initializeDateFormatting('fr'));

  testWidgets('déconnexion hors ligne : Connexion affichée, jetons effacés, pas de session au relancement',
      (tester) async {
    final env = TestEnv.demoSession();
    env.storage.refresh = 'mock-refresh-1'; // sans jeton de rafraîchissement, l'API ne serait pas appelée
    final remote = _OfflineLogoutRemote(env.backend);
    final overrides = [authRemoteDataSourceProvider.overrideWithValue(remote)];

    await pumpKovoitApp(tester, env: env, overrides: overrides);
    expect(find.text(_home), findsOneWidget);

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    await scrollAndTap(tester, find.text('Se déconnecter'));

    expect(remote.logouts, ['mock-refresh-1'], reason: 'POST /auth/deconnexion/ tenté, et levé NetworkApiException');
    expect(find.text(_loginTitle), findsOneWidget);
    expect(env.storage.access, isNull);
    expect(env.storage.refresh, isNull);

    // Relancement de l'app avec le même stockage : arbre démonté puis nouvelle ProviderScope.
    await tester.pumpWidget(const SizedBox());
    expect(remote.meCalls, greaterThan(0), reason: 'sonde : le premier lancement a bien restauré la session par GET /moi/');
    remote.meCalls = 0;
    await pumpKovoitApp(tester, env: env, overrides: overrides);

    expect(find.text(_loginTitle), findsOneWidget);
    expect(find.text(_home), findsNothing);
    expect(remote.meCalls, 0, reason: 'GET /moi/ ne doit pas être appelé sans session');
  });
}
