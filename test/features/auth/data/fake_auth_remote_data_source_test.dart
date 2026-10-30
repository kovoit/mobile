import 'package:flutter_test/flutter_test.dart';
import 'package:kovoit/core/config/demo_account.dart';
import 'package:kovoit/core/mock/fake_backend.dart';
import 'package:kovoit/core/network/api_exception.dart';
import 'package:kovoit/features/auth/data/datasources/fake_auth_remote_data_source.dart';

import '../../../helpers/test_app.dart';

/// Le faux serveur suit le contrat M-004 T0 (mêmes codes, mêmes formes) : c'est lui que l'app
/// utilise en démo et dans les tests de widgets.
void main() {
  late DateTime now;
  late FakeBackend backend;
  late FakeAuthRemoteDataSource remote;

  setUp(() {
    now = DateTime.utc(2026, 10, 30, 15);
    backend = FakeBackend(InMemoryTokenStorage(), latency: Duration.zero, clock: () => now);
    remote = FakeAuthRemoteDataSource(backend);
  });

  Future<void> register({
    String email = 'afi@exemple.com',
    String telephone = '+22891234567',
    String motDePasse = 'Lome-Trajet-2026',
    bool cgu = true,
    String prenom = 'Afi',
  }) =>
      remote.register(
        prenom: prenom,
        nom: 'Amégan',
        email: email,
        telephone: telephone,
        motDePasse: motDePasse,
        cguAcceptees: cgu,
      );

  Matcher apiError<T extends ApiException>(String code) =>
      throwsA(isA<T>().having((e) => e.code, 'code', code));

  group('connexion', () {
    test('compte de démo : SESSION, nouveau_compte faux', () async {
      final session = await remote.login(email: ' DEMO@kovoit.tg ', motDePasse: DemoAccount.password);

      expect(session.nouveauCompte, isFalse);
      expect(session.access, 'mock-access-1');
      expect(session.utilisateur.email, DemoAccount.email);
    });

    test('mauvais mot de passe, adresse inconnue, compte sans mot de passe (D-69) : même 401', () async {
      for (final (email, password) in [
        (DemoAccount.email, 'mauvais-mot-de-passe'),
        ('inconnu@exemple.com', DemoAccount.password),
        (DemoAccount.legacyEmail, ''),
      ]) {
        await expectLater(
          remote.login(email: email, motDePasse: password),
          throwsA(
            isA<UnauthorizedApiException>()
                .having((e) => e.code, 'code', 'IDENTIFIANTS_INVALIDES')
                .having((e) => e.message, 'message', 'Email ou mot de passe incorrect.'),
          ),
        );
        now = now.add(const Duration(minutes: 1)); // hors de la limite par minute
      }
    });

    test('adresse non vérifiée : 403 EMAIL_NON_VERIFIE seulement avec le bon mot de passe (D-73)', () async {
      await register();

      await expectLater(
        remote.login(email: 'afi@exemple.com', motDePasse: 'faux-mot-de-passe'),
        apiError<UnauthorizedApiException>('IDENTIFIANTS_INVALIDES'),
      );
      await expectLater(
        remote.login(email: 'afi@exemple.com', motDePasse: 'Lome-Trajet-2026'),
        apiError<ForbiddenApiException>('EMAIL_NON_VERIFIE'),
      );
    });

    test('compte supprimé : 401 identique (D-74)', () async {
      backend.deleteUser(1);

      await expectLater(
        remote.login(email: DemoAccount.email, motDePasse: DemoAccount.password),
        apiError<UnauthorizedApiException>('IDENTIFIANTS_INVALIDES'),
      );
    });

    test('compte suspendu : connexion acceptée (D-74)', () async {
      backend.updateUser(1, {'statut_compte': 'suspendu'});

      final session = await remote.login(email: DemoAccount.email, motDePasse: DemoAccount.password);

      expect(session.utilisateur.statutCompte, 'suspendu');
    });

    test('plus de 5 requêtes par minute : 429 TROP_DE_REQUETES', () async {
      for (var i = 0; i < 5; i++) {
        await expectLater(
          remote.login(email: DemoAccount.email, motDePasse: 'faux'),
          throwsA(isA<UnauthorizedApiException>()),
        );
      }
      await expectLater(
        remote.login(email: DemoAccount.email, motDePasse: DemoAccount.password),
        apiError<TooManyAttemptsApiException>('TROP_DE_REQUETES'),
      );
    });
  });

  group('inscription', () {
    test('201 CODE_ENVOYE (délai 60 s), compte non vérifié, aucun jeton', () async {
      final code = await remote.register(
        prenom: 'Afi',
        nom: 'Amégan',
        email: ' AFI@Exemple.com',
        telephone: '+22891234567',
        motDePasse: 'Lome-Trajet-2026',
        cguAcceptees: true,
      );

      expect(code.email, 'afi@exemple.com');
      expect(code.delaiRenvoiS, 60);
      final user = backend.userByEmail('afi@exemple.com')!;
      expect(user.fields['email_verifie'], isFalse);
      expect(backend.profilJson(user.id)['profil_complet'], isTrue, reason: 'aucun nouveau compte ne passe par « Profil à compléter » (D-80)');
    });

    test('le mot de passe n’apparaît jamais dans le JSON du profil', () async {
      await register();
      final user = backend.userByEmail('afi@exemple.com')!;

      expect(backend.profilJson(user.id).values.map((v) => '$v'), isNot(contains('Lome-Trajet-2026')));
      expect(backend.profilJson(user.id).keys, isNot(contains('mot_de_passe')));
    });

    test('numéro déjà utilisé par un autre compte : accepté (D-66)', () async {
      await register(telephone: '+22890123456'); // numéro du compte démo
      expect(backend.userByEmail('afi@exemple.com'), isNotNull);
    });

    test('adresse déjà inscrite, vérifiée ou non : 409 EMAIL_DEJA_UTILISE avec erreurs.email (D-75)', () async {
      await register();
      for (final email in [DemoAccount.email, 'afi@exemple.com']) {
        await expectLater(
          register(email: email),
          throwsA(
            isA<ConflictApiException>()
                .having((e) => e.code, 'code', 'EMAIL_DEJA_UTILISE')
                .having((e) => e.details['email'], 'erreurs.email', isNotEmpty),
          ),
        );
      }
    });

    test('CGU non acceptées : 400 DONNEES_INVALIDES (erreurs.cgu_acceptees)', () async {
      await expectLater(
        register(cgu: false),
        throwsA(
          isA<BadRequestApiException>()
              .having((e) => e.code, 'code', 'DONNEES_INVALIDES')
              .having((e) => e.fieldErrors.keys, 'champs', contains('cgu_acceptees')),
        ),
      );
    });

    test('téléphone invalide : 400 TELEPHONE_INVALIDE (erreurs.telephone)', () async {
      await expectLater(
        register(telephone: '+22880000000'),
        throwsA(
          isA<BadRequestApiException>()
              .having((e) => e.code, 'code', 'TELEPHONE_INVALIDE')
              .having((e) => e.fieldErrors.keys, 'champs', contains('telephone')),
        ),
      );
    });

    test('mot de passe faible (court, numérique, courant, proche du prénom) : 400 MOT_DE_PASSE_FAIBLE', () async {
      for (final motDePasse in ['Abc-12', '20261030', 'motdepasse', 'Afi-Afi-Afi']) {
        await expectLater(
          register(motDePasse: motDePasse),
          throwsA(
            isA<BadRequestApiException>()
                .having((e) => e.code, 'code', 'MOT_DE_PASSE_FAIBLE')
                .having((e) => e.fieldErrors['mot_de_passe'], 'erreurs.mot_de_passe', isNotNull),
          ),
          reason: motDePasse,
        );
      }
      expect(backend.userByEmail('afi@exemple.com'), isNull);
    });

    test('vérification : bon code → SESSION nouveau_compte vrai ; code faux ou déjà utilisé → CODE_OTP_INVALIDE', () async {
      await register();

      await expectLater(
        remote.verifyEmail(email: 'afi@exemple.com', code: '000000'),
        apiError<BadRequestApiException>('CODE_OTP_INVALIDE'),
      );
      final session = await remote.verifyEmail(email: 'afi@exemple.com', code: DemoAccount.otpCode);
      expect(session.nouveauCompte, isTrue);
      expect(session.utilisateur.emailVerifie, isTrue);
      await expectLater(
        remote.verifyEmail(email: 'afi@exemple.com', code: DemoAccount.otpCode),
        apiError<BadRequestApiException>('CODE_OTP_INVALIDE'),
      );

      final login = await remote.login(email: 'afi@exemple.com', motDePasse: 'Lome-Trajet-2026');
      expect(login.nouveauCompte, isFalse);
    });

    test('renvoyer-code : même réponse pour une adresse inconnue ou déjà vérifiée', () async {
      for (final email in ['inconnu@exemple.com', DemoAccount.email]) {
        final code = await remote.resendVerificationCode(email);
        expect(code.email, email);
        expect(code.delaiRenvoiS, 60);
      }
      expect(backend.codesSent, isEmpty);
    });

    test('renvoyer-code : 429 au plafond horaire d’un compte non vérifié', () async {
      await register();
      for (var i = 1; i < FakeBackend.otpMaxPerHour; i++) {
        now = now.add(const Duration(minutes: 2));
        await remote.resendVerificationCode('afi@exemple.com');
      }
      now = now.add(const Duration(minutes: 2));
      await expectLater(
        remote.resendVerificationCode('afi@exemple.com'),
        apiError<TooManyAttemptsApiException>('TROP_DE_REQUETES'),
      );
    });
  });

  group('mot de passe oublié', () {
    test('adresse inconnue : même CODE_ENVOYE, aucun code', () async {
      final code = await remote.requestPasswordReset('inconnu@exemple.com');

      expect(code.email, 'inconnu@exemple.com');
      expect(code.delaiRenvoiS, 60);
      expect(backend.codesSent, isEmpty);
    });

    test('mot de passe faible contrôlé avant le code : le code reste valable', () async {
      await remote.requestPasswordReset(DemoAccount.email);

      await expectLater(
        remote.resetPassword(email: DemoAccount.email, code: DemoAccount.otpCode, motDePasse: '12345678'),
        apiError<BadRequestApiException>('MOT_DE_PASSE_FAIBLE'),
      );
      await remote.resetPassword(email: DemoAccount.email, code: DemoAccount.otpCode, motDePasse: 'Nouveau-Trajet-26');

      await expectLater(
        remote.login(email: DemoAccount.email, motDePasse: DemoAccount.password),
        apiError<UnauthorizedApiException>('IDENTIFIANTS_INVALIDES'),
      );
      final session = await remote.login(email: DemoAccount.email, motDePasse: 'Nouveau-Trajet-26');
      expect(session.access, 'mock-access-1');
    });

    test('code faux, ou aucun code demandé : CODE_OTP_INVALIDE', () async {
      await expectLater(
        remote.resetPassword(email: DemoAccount.email, code: DemoAccount.otpCode, motDePasse: 'Nouveau-Trajet-26'),
        apiError<BadRequestApiException>('CODE_OTP_INVALIDE'),
      );
      await remote.requestPasswordReset(DemoAccount.email);
      await expectLater(
        remote.resetPassword(email: DemoAccount.email, code: '000000', motDePasse: 'Nouveau-Trajet-26'),
        apiError<BadRequestApiException>('CODE_OTP_INVALIDE'),
      );
    });

    test('compte ancien sans mot de passe (D-69) : premier mot de passe, puis profil à compléter (D-80)', () async {
      await remote.requestPasswordReset(DemoAccount.legacyEmail);
      await remote.resetPassword(email: DemoAccount.legacyEmail, code: DemoAccount.otpCode, motDePasse: 'Premier-Trajet-26');

      final session = await remote.login(email: DemoAccount.legacyEmail, motDePasse: 'Premier-Trajet-26');

      expect(session.utilisateur.profilComplet, isFalse);
    });

    test('réinitialisation d’un compte non vérifié : adresse vérifiée (D-77)', () async {
      await register();
      now = now.add(const Duration(minutes: 2));
      await remote.requestPasswordReset('afi@exemple.com');
      await remote.resetPassword(email: 'afi@exemple.com', code: DemoAccount.otpCode, motDePasse: 'Nouveau-Trajet-26');

      final session = await remote.login(email: 'afi@exemple.com', motDePasse: 'Nouveau-Trajet-26');

      expect(session.utilisateur.emailVerifie, isTrue);
    });
  });
}
