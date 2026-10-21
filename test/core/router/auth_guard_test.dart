import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kovoit/core/network/api_exception.dart';
import 'package:kovoit/core/router/auth_guard.dart';
import 'package:kovoit/core/router/routes.dart';
import 'package:kovoit/features/auth/domain/entities/app_user.dart';

AppUser _user({bool complete = true}) => AppUser(
      id: '1',
      prenom: complete ? 'Kodjo' : '',
      nom: complete ? 'Mensah' : '',
      email: 'kodjo@exemple.com',
      telephone: complete ? '+22890123456' : null,
      profilComplet: complete,
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

    test('accède à la saisie de l’e-mail et du code', () {
      expect(authRedirect(session, Routes.login), isNull);
      expect(authRedirect(session, Routes.otp), isNull);
    });

    test('est renvoyé vers la connexion ailleurs', () {
      expect(authRedirect(session, Routes.splash), Routes.login);
      expect(authRedirect(session, Routes.home), Routes.login);
      expect(authRedirect(session, Routes.completeProfile), Routes.login);
    });
  });

  test('nouveau compte : profil à compléter avant l’application', () {
    final session = AsyncData<AppUser?>(_user(complete: false));
    expect(authRedirect(session, Routes.home), Routes.completeProfile);
    expect(authRedirect(session, Routes.otp), Routes.completeProfile);
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
    expect(authRedirect(session, Routes.otp), Routes.home);
    expect(authRedirect(session, Routes.completeProfile), Routes.home);
  });
}
