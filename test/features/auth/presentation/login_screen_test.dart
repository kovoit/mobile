import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kovoit/core/config/demo_account.dart';
import 'package:kovoit/core/network/api_exception.dart';
import 'package:kovoit/core/utils/app_logger.dart';
import 'package:kovoit/features/auth/domain/entities/otp_challenge.dart';
import 'package:kovoit/features/auth/domain/repositories/auth_repository.dart';
import 'package:kovoit/features/auth/presentation/providers/auth_providers.dart';
import 'package:kovoit/features/auth/presentation/providers/session_controller.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/flows.dart';
import '../../../helpers/log_capture.dart';
import '../../../helpers/test_app.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

const _email = 'ama.mensah@exemple.tg';
const _password = 'Lome-Trajet-2026';
const _loginSubtitle = 'Connectez-vous pour commencer votre trajet';

/// Enveloppe d'erreur du contrat (voir test/fixtures/backend/auth_erreur_*.json).
ApiException _error(int status, String code, String message) => ApiException.fromResponse(status, {
      'statut': 'failed',
      'message': message,
      'reponse': {'code': code, 'erreurs': <String, dynamic>{}},
    });

EditableText _passwordInput(WidgetTester tester) =>
    tester.widget<EditableText>(find.descendant(of: authField('Mot de passe'), matching: find.byType(EditableText)));

void main() {
  setUpAll(() => initializeDateFormatting('fr'));

  group('CA-072-5 · écran Connexion', () {
    testWidgets('e-mail, mot de passe masqué avec « afficher / masquer », « Se connecter », sans Google', (tester) async {
      await pumpKovoitApp(tester);

      expect(find.text(_loginSubtitle), findsOneWidget);
      expect(authField('Adresse e-mail'), findsOneWidget);
      expect(authField('Mot de passe'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Se connecter'), findsOneWidget);
      expect(find.textContaining(RegExp('google', caseSensitive: false)), findsNothing);
      expect(find.bySemanticsLabel(RegExp('google', caseSensitive: false)), findsNothing);

      expect(_passwordInput(tester).obscureText, isTrue, reason: 'masqué par défaut');
      await tester.tap(find.byTooltip('Afficher le mot de passe'));
      await tester.pump();
      expect(_passwordInput(tester).obscureText, isFalse);
      await tester.tap(find.byTooltip('Masquer le mot de passe'));
      await tester.pump();
      expect(_passwordInput(tester).obscureText, isTrue);
    });

    testWidgets('« Créer un compte » ouvre l’Inscription', (tester) async {
      await pumpKovoitApp(tester);

      await scrollAndTap(tester, find.text('Créer un compte'));

      expect(find.text('Créer un compte'), findsOneWidget); // titre de l'Inscription
      expect(authField('Confirmer le mot de passe'), findsOneWidget);
      expect(find.text(_loginSubtitle), findsNothing);
    });

    testWidgets('« Mot de passe oublié ? » ouvre l’étape 1 du Mot de passe oublié', (tester) async {
      await pumpKovoitApp(tester);

      await scrollAndTap(tester, find.text('Mot de passe oublié ?'));

      expect(find.text('Mot de passe oublié'), findsOneWidget);
      expect(find.text('ÉTAPE 1 · ADRESSE E-MAIL'), findsOneWidget);
      expect(find.text('Recevoir le code'), findsOneWidget);
    });
  });

  group('avec un dépôt simulé', () {
    late _MockAuthRepository repository;

    setUp(() {
      repository = _MockAuthRepository();
      when(() => repository.restoreSession()).thenAnswer((_) async => null);
      when(() => repository.resendVerificationCode(any()))
          .thenAnswer((_) async => const OtpChallenge(email: _email, resendIn: Duration(seconds: 60)));
    });

    Future<TestEnv> pump(WidgetTester tester) =>
        pumpKovoitApp(tester, overrides: [authRepositoryProvider.overrideWithValue(repository)]);

    testWidgets('CA-072-2 · 403 EMAIL_NON_VERIFIE : Vérification avec l’e-mail, compte à rebours puis « Renvoyer »', (tester) async {
      when(() => repository.login(email: any(named: 'email'), password: any(named: 'password'))).thenThrow(
        _error(403, 'EMAIL_NON_VERIFIE', 'Adresse e-mail non vérifiée. Saisissez le code reçu par e-mail.'),
      );
      final env = await pump(tester);

      await loginWithPassword(tester, '  Ama.Mensah@Exemple.tg ', _password);

      expect(find.text('Vérification'), findsOneWidget);
      expect(find.text(_email), findsOneWidget, reason: 'adresse saisie, normalisée');
      expect(find.text('Renvoyer le code dans 01:00'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Renvoyer le code'), findsNothing);
      expect(env.storage.access, isNull, reason: 'aucun jeton');
      verify(() => repository.login(email: '  Ama.Mensah@Exemple.tg ', password: _password)).called(1);
      verifyNever(() => repository.resendVerificationCode(any())); // le serveur a déjà envoyé le code

      env.now = env.now.add(const Duration(seconds: 60));
      await tester.pump(const Duration(seconds: 60));
      await tester.tap(find.widgetWithText(TextButton, 'Renvoyer le code'));
      await tester.pumpAndSettle();

      verify(() => repository.resendVerificationCode(_email)).called(1);
      expect(find.text('Renvoyer le code dans 01:00'), findsOneWidget);
    });

    testWidgets('401 IDENTIFIANTS_INVALIDES : message de l’API, reste sur la Connexion, aucun code', (tester) async {
      when(() => repository.login(email: any(named: 'email'), password: any(named: 'password')))
          .thenThrow(_error(401, 'IDENTIFIANTS_INVALIDES', 'Identifiants refusés (texte de l’API).'));
      final env = await pump(tester);

      await loginWithPassword(tester, _email, 'mauvais-mot-de-passe');

      expect(find.text('Identifiants refusés (texte de l’API).'), findsOneWidget);
      expect(find.text(_loginSubtitle), findsOneWidget);
      expect(find.text('Vérification'), findsNothing);
      expect(env.storage.access, isNull);
      verifyNever(() => repository.resendVerificationCode(any()));
    });

    testWidgets('429 TROP_DE_REQUETES : message de l’API', (tester) async {
      when(() => repository.login(email: any(named: 'email'), password: any(named: 'password')))
          .thenThrow(_error(429, 'TROP_DE_REQUETES', 'Trop de tentatives. Réessayez dans une minute.'));
      await pump(tester);

      await loginWithPassword(tester, _email, _password);

      expect(find.text('Trop de tentatives. Réessayez dans une minute.'), findsOneWidget);
      expect(find.text(_loginSubtitle), findsOneWidget);
    });

    testWidgets('format vide : aucun appel', (tester) async {
      await pump(tester);

      await scrollAndTap(tester, find.text('Se connecter'));

      expect(find.text('Le mot de passe est obligatoire.'), findsOneWidget);
      verifyNever(() => repository.login(email: any(named: 'email'), password: any(named: 'password')));
    });
  });

  testWidgets('CA-072-2 · adresse inconnue et mauvais mot de passe : même réponse', (tester) async {
    await pumpKovoitApp(tester);

    await loginWithPassword(tester, 'inconnu@exemple.tg', _password);
    final unknown = tester.widgetList<Text>(find.textContaining('incorrect')).map((t) => t.data).toList();
    await loginWithPassword(tester, DemoAccount.email, 'mauvais-mot-de-passe');
    final wrongPassword = tester.widgetList<Text>(find.textContaining('incorrect')).map((t) => t.data).toList();

    expect(unknown, ['Email ou mot de passe incorrect.']);
    expect(wrongPassword, unknown);
  });

  testWidgets('CA0 · après une connexion : mot de passe ni dans les jetons, ni dans le journal, ni dans la session', (tester) async {
    final logs = LogCapture.start();
    appLogger.t('sonde du journal'); // niveau filtré : capturé sans être affiché
    expect(logs.mentions('sonde du journal'), isTrue, reason: 'la capture du journal fonctionne');
    final env = await pumpKovoitApp(tester);

    await loginWithPassword(tester, DemoAccount.email, DemoAccount.password);

    expect(find.text('Le même chemin, à plusieurs. Et moins cher.'), findsOneWidget);
    expect(env.storage.access, isNotNull);
    expect([env.storage.access, env.storage.refresh], everyElement(isNot(contains(DemoAccount.password))));
    expect(logs.mentions(DemoAccount.password), isFalse);
    final container = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
    final user = container.read(sessionControllerProvider).value!;
    expect(
      [user.id, user.prenom, user.nom, user.email, user.telephone, user.toString()],
      everyElement(isNot(contains(DemoAccount.password))),
    );
  });
}
