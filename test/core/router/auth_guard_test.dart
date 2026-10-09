import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kovoit/core/network/api_exception.dart';
import 'package:kovoit/core/router/auth_guard.dart';
import 'package:kovoit/core/router/routes.dart';
import 'package:kovoit/features/auth/domain/entities/app_user.dart';

AppUser _user({String? telephone = '+22890123456', bool verified = true}) => AppUser(
      id: 1,
      prenom: 'Kodjo',
      nom: 'Mensah',
      email: 'kodjo@exemple.com',
      telephone: telephone,
      telephoneVerifie: verified,
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

    test('accède aux écrans publics', () {
      for (final route in Routes.publicAuth) {
        expect(authRedirect(session, route), isNull, reason: route);
      }
    });

    test('est renvoyé vers la connexion ailleurs', () {
      expect(authRedirect(session, Routes.splash), Routes.login);
      expect(authRedirect(session, Routes.home), Routes.login);
      expect(authRedirect(session, Routes.otp), Routes.login);
    });
  });

  test('KYC non vérifié : la navigation reste ouverte (contrôle au moment de l’action)', () {
    final session = AsyncData<AppUser?>(_user());
    expect(session.value!.kycPassager, KycStatus.nonVerifie);
    expect(authRedirect(session, Routes.home), isNull);
    expect(authRedirect(session, Routes.kyc('passager')), isNull);
  });

  test('compte Google sans numéro → saisie du numéro', () {
    final session = AsyncData<AppUser?>(_user(telephone: null, verified: false));
    expect(authRedirect(session, Routes.home), Routes.phone);
    expect(authRedirect(session, Routes.otp), Routes.phone);
    expect(authRedirect(session, Routes.phone), isNull);
  });

  test('numéro non vérifié → code SMS (modification du numéro autorisée)', () {
    final session = AsyncData<AppUser?>(_user(verified: false));
    expect(authRedirect(session, Routes.home), Routes.otp);
    expect(authRedirect(session, Routes.login), Routes.otp);
    expect(authRedirect(session, Routes.otp), isNull);
    expect(authRedirect(session, Routes.phone), isNull);
  });

  test('téléphone vérifié → application, écrans d’entrée renvoyés vers l’accueil', () {
    final session = AsyncData<AppUser?>(_user());
    expect(authRedirect(session, Routes.home), isNull);
    expect(authRedirect(session, Routes.vehicle), isNull);
    expect(authRedirect(session, Routes.profile), isNull);
    expect(authRedirect(session, Routes.splash), Routes.home);
    expect(authRedirect(session, Routes.login), Routes.home);
    expect(authRedirect(session, Routes.otp), Routes.home);
  });
}
