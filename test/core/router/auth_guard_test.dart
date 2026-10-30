import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kovoit/core/network/api_exception.dart';
import 'package:kovoit/core/router/auth_guard.dart';
import 'package:kovoit/core/router/routes.dart';
import 'package:kovoit/core/config/demo_account.dart';
import 'package:kovoit/features/auth/data/datasources/fake_auth_remote_data_source.dart';
import 'package:kovoit/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:kovoit/features/auth/domain/entities/app_user.dart';
import 'package:kovoit/features/auth/domain/entities/registration.dart';

import '../../helpers/test_app.dart';

/// Écrans de l'application (hors écrans d'entrée), pour vérifier qu'aucun n'échappe à la garde.
final _appScreens = [
  Routes.home,
  Routes.searchResults,
  Routes.myTrips,
  Routes.booking('1'),
  Routes.driverTrip('1'),
  Routes.profile,
  Routes.kyc('passager'),
  Routes.vehicle,
  Routes.becomeDriver,
  Routes.wallet,
  Routes.notifications,
  Routes.deleteAccount,
];

final _entryScreens = [Routes.splash, ...Routes.publicAuth, Routes.completeProfile, Routes.acceptTerms];

AppUser _user({bool complete = true, bool cgu = true}) => AppUser(
      id: '1',
      prenom: complete ? 'Kodjo' : '',
      nom: complete ? 'Mensah' : '',
      email: 'kodjo@exemple.com',
      telephone: complete ? '+22890123456' : null,
      profilComplet: complete,
      cguAcceptees: cgu,
    );

void main() {
  group('session en chargement ou en erreur', () {
    test('reste sur le Splash', () {
      expect(authRedirect(const AsyncLoading(), Routes.splash), isNull);
      expect(authRedirect(const AsyncLoading(), Routes.home), Routes.splash);
      expect(authRedirect(const AsyncError<AppUser?>(NetworkApiException(), StackTrace.empty), Routes.login), Routes.splash);
    });
  });

  group('déconnecté', () {
    const session = AsyncData<AppUser?>(null);

    test('accède à la Connexion, à l’Inscription, à la Vérification et au Mot de passe oublié', () {
      expect(authRedirect(session, Routes.login), isNull);
      expect(authRedirect(session, Routes.register), isNull);
      expect(authRedirect(session, Routes.emailVerification), isNull);
      expect(authRedirect(session, Routes.forgotPassword), isNull);
    });

    test('est renvoyé vers la connexion ailleurs', () {
      expect(authRedirect(session, Routes.splash), Routes.login);
      expect(authRedirect(session, Routes.home), Routes.login);
      expect(authRedirect(session, Routes.completeProfile), Routes.login);
    });
  });

  test('compte ancien sans nom ou téléphone (D-80) : profil à compléter avant l’application', () {
    final session = AsyncData<AppUser?>(_user(complete: false));
    expect(authRedirect(session, Routes.home), Routes.completeProfile);
    expect(authRedirect(session, Routes.login), Routes.completeProfile);
    expect(authRedirect(session, Routes.emailVerification), Routes.completeProfile);
    expect(authRedirect(session, Routes.completeProfile), isNull);
  });

  test('KYC non vérifié : la navigation reste ouverte (contrôle au moment de l’action)', () {
    final session = AsyncData<AppUser?>(_user());
    expect(session.value!.kycPassager, KycStatus.nonVerifie);
    expect(authRedirect(session, Routes.home), isNull);
    expect(authRedirect(session, Routes.kyc('passager')), isNull);
  });

  test('profil complet → application, écrans d’entrée renvoyés vers l’accueil', () {
    final session = AsyncData<AppUser?>(_user());
    expect(authRedirect(session, Routes.home), isNull);
    expect(authRedirect(session, Routes.vehicle), isNull);
    expect(authRedirect(session, Routes.profile), isNull);
    expect(authRedirect(session, Routes.splash), Routes.home);
    expect(authRedirect(session, Routes.login), Routes.home);
    expect(authRedirect(session, Routes.register), Routes.home);
    expect(authRedirect(session, Routes.emailVerification), Routes.home);
    expect(authRedirect(session, Routes.forgotPassword), Routes.home);
    expect(authRedirect(session, Routes.completeProfile), Routes.home);
  });

  test('CA-003-4 · compte créé par l’inscription puis vérifié : accueil, jamais « Profil à compléter »', () async {
    final env = TestEnv();
    final repository = AuthRepositoryImpl(
      remote: FakeAuthRemoteDataSource(env.backend),
      tokenStorage: env.storage,
      capture: env.camera,
    );
    await repository.register(const Registration(
      prenom: 'Ama',
      nom: 'Mensah',
      email: 'ama.mensah@exemple.tg',
      telephone: '+22891234567',
      motDePasse: 'Lome-Trajet-2026',
      cguAcceptees: true,
    ));
    await repository.verifyEmail(email: 'ama.mensah@exemple.tg', code: DemoAccount.otpCode);

    // Ouverture de l'app : session restaurée par GET /moi/.
    final user = await repository.restoreSession();
    expect(user, isNotNull);
    expect(user!.profilComplet, isTrue);
    expect(user.cguAcceptees, isTrue, reason: 'CA-004-2 : CGU acceptées à l’inscription, pas d’écran « Conditions »');

    final session = AsyncData<AppUser?>(user);
    expect(authRedirect(session, Routes.splash), Routes.home);
    for (final location in [..._entryScreens, ..._appScreens]) {
      expect(authRedirect(session, location), isNot(Routes.completeProfile), reason: location);
      expect(authRedirect(session, location), isNot(Routes.acceptTerms), reason: location);
    }
  });

  test('CA-004-3 · cgu_acceptees = faux (nouvelle version des CGU) : « Conditions » avant tout autre écran', () {
    final session = AsyncData<AppUser?>(_user(cgu: false));
    for (final location in [..._appScreens, Routes.splash, ...Routes.publicAuth, Routes.completeProfile]) {
      expect(authRedirect(session, location), Routes.acceptTerms, reason: location);
    }
    expect(authRedirect(session, Routes.acceptTerms), isNull);

    // Une fois acceptées : l'application, et « Conditions » renvoie vers l'accueil.
    final accepted = AsyncData<AppUser?>(_user());
    expect(authRedirect(accepted, Routes.acceptTerms), Routes.home);
    expect(authRedirect(accepted, Routes.profile), isNull);
  });
}

