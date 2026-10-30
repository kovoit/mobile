import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kovoit/core/config/demo_account.dart';
import 'package:kovoit/core/network/api_exception.dart';
import 'package:kovoit/core/utils/app_logger.dart';
import 'package:kovoit/features/auth/domain/entities/otp_challenge.dart';
import 'package:kovoit/features/auth/domain/entities/registration.dart';
import 'package:kovoit/features/auth/domain/repositories/auth_repository.dart';
import 'package:kovoit/features/auth/presentation/providers/auth_providers.dart';
import 'package:kovoit/features/auth/presentation/providers/email_verification_controller.dart';
import 'package:kovoit/features/auth/presentation/providers/session_controller.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/flows.dart';
import '../../../helpers/log_capture.dart';
import '../../../helpers/test_app.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

const _password = 'Lome-Trajet-2026';
const _email = 'ama.mensah@exemple.tg';

/// Erreur dont le texte n'est pas celui du mobile : prouve que l'écran affiche le message de l'API.
ApiException _conflict({Map<String, dynamic>? erreurs, String message = 'Un compte existe déjà avec cette adresse e-mail.'}) =>
    ApiException.fromResponse(409, {
      'statut': 'failed',
      'message': message,
      'reponse': {'code': 'EMAIL_DEJA_UTILISE', 'erreurs': erreurs ?? {}},
    });

/// Message sous le champ [label] (le texte d'erreur est rendu dans le champ lui-même).
Finder _errorUnder(String label, String message) =>
    find.descendant(of: authField(label), matching: find.text(message));

void main() {
  setUpAll(() {
    registerFallbackValue(const Registration(
      prenom: '',
      nom: '',
      email: '',
      telephone: '',
      motDePasse: '',
      cguAcceptees: false,
    ));
    return initializeDateFormatting('fr');
  });

  late _MockAuthRepository repository;

  setUp(() {
    repository = _MockAuthRepository();
    when(() => repository.restoreSession()).thenAnswer((_) async => null);
  });

  Future<TestEnv> openRegister(WidgetTester tester) async {
    final env = await pumpKovoitApp(tester, overrides: [authRepositoryProvider.overrideWithValue(repository)]);
    await scrollAndTap(tester, find.text('Créer un compte'));
    expect(find.text('Créer un compte'), findsOneWidget); // titre de l'Inscription
    return env;
  }

  Future<void> submit(WidgetTester tester) => scrollAndTap(tester, find.text('Créer mon compte'));

  group('CA-070-5 · format contrôlé avant tout appel', () {
    testWidgets('confirmation différente : message sous la confirmation, aucun appel', (tester) async {
      await openRegister(tester);

      await fillRegistration(tester, confirmation: 'Lome-Trajet-2027');
      await submit(tester);

      expect(_errorUnder('Confirmer le mot de passe', 'Les mots de passe ne correspondent pas.'), findsOneWidget);
      expect(find.text('Créer mon compte'), findsOneWidget);
      verifyNever(() => repository.register(any()));
    });

    testWidgets('mot de passe de 7 caractères : message sous le mot de passe, aucun appel', (tester) async {
      await openRegister(tester);

      await fillRegistration(tester, password: 'Lome-26');
      await submit(tester);

      expect(_errorUnder('Mot de passe', 'Au moins 8 caractères.'), findsOneWidget);
      verifyNever(() => repository.register(any()));
    });

    testWidgets('8 caractères : le format passe, le backend juge (appel fait)', (tester) async {
      when(() => repository.register(any()))
          .thenAnswer((_) async => const OtpChallenge(email: _email, resendIn: Duration(seconds: 60)));
      await openRegister(tester);

      await fillRegistration(tester, password: 'Lome-026');
      await submit(tester);

      expect(find.text('Au moins 8 caractères.'), findsNothing);
      verify(() => repository.register(any())).called(1);
    });
  });

  testWidgets('CA-004-2 · case CGU non cochée : signalée, aucun appel', (tester) async {
    await openRegister(tester);

    await fillRegistration(tester, acceptTerms: false);
    await submit(tester);

    expect(find.text('Acceptez les conditions d’utilisation pour continuer.'), findsOneWidget);
    expect(find.text('Vérification'), findsNothing);
    verifyNever(() => repository.register(any()));
  });

  group('CA-070-5 · réponse 409 EMAIL_DEJA_UTILISE', () {
    testWidgets('message de l’API sous le champ e-mail, reste sur l’Inscription', (tester) async {
      when(() => repository.register(any())).thenThrow(_conflict(erreurs: {
        'email': ['Adresse déjà inscrite (texte de l’API).'],
      }));
      await openRegister(tester);

      await fillRegistration(tester);
      await submit(tester);

      expect(_errorUnder('Adresse e-mail', 'Adresse déjà inscrite (texte de l’API).'), findsOneWidget);
      expect(find.text('Vérification'), findsNothing);
      verify(() => repository.register(any())).called(1);
    });

    testWidgets('sans erreur par champ : message général de l’API', (tester) async {
      when(() => repository.register(any())).thenThrow(_conflict(message: 'Compte déjà existant (texte de l’API).'));
      await openRegister(tester);

      await fillRegistration(tester);
      await submit(tester);

      expect(find.text('Compte déjà existant (texte de l’API).'), findsOneWidget);
      expect(find.text('Créer mon compte'), findsOneWidget);
    });
  });

  testWidgets('CA-070-5 · succès : Vérification avec l’e-mail saisi ; données envoyées au dépôt', (tester) async {
    when(() => repository.register(any()))
        .thenAnswer((_) async => const OtpChallenge(email: _email, resendIn: Duration(seconds: 60)));
    final env = await openRegister(tester);

    await fillRegistration(tester, email: _email, phone: '91 23 45 67');
    await submit(tester);

    expect(find.text('Vérification'), findsOneWidget);
    expect(find.text(_email), findsOneWidget);
    final sent = verify(() => repository.register(captureAny())).captured.single as Registration;
    expect(sent.email, _email);
    expect(sent.telephone, '+22891234567');
    expect(sent.motDePasse, _password);
    expect(sent.cguAcceptees, isTrue);
    expect(sent.toString(), isNot(contains(_password)));
    expect(env.storage.access, isNull, reason: 'aucun jeton avant la vérification de l’e-mail');
  });

  testWidgets('CA0 / R-02 · inscription puis vérification : mot de passe ni stocké, ni journalisé, ni dans un état', (tester) async {
    final logs = LogCapture.start();
    appLogger.t('sonde du journal'); // niveau filtré : capturé sans être affiché
    expect(logs.mentions('sonde du journal'), isTrue, reason: 'la capture du journal fonctionne');

    final env = await pumpKovoitApp(tester);
    await registerFromLogin(tester, email: _email, password: _password);
    expect(find.text('Vérification'), findsOneWidget);

    final container = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
    final verification = container.read(emailVerificationControllerProvider);
    expect(verification.email, _email);
    expect([verification.email, verification.error], everyElement(isNot(contains(_password))));

    await enterEmailCode(tester, DemoAccount.otpCode);
    expect(find.text('Le même chemin, à plusieurs. Et moins cher.'), findsOneWidget);

    expect(env.storage.access, isNotNull);
    expect(env.storage.access, isNot(contains(_password)));
    expect(env.storage.refresh, isNot(contains(_password)));
    expect(logs.mentions(_password), isFalse);
    final user = container.read(sessionControllerProvider).value!;
    expect(
      [user.id, user.prenom, user.nom, user.email, user.telephone, user.toString()],
      everyElement(isNot(contains(_password))),
    );
    expect(container.read(emailVerificationControllerProvider).email, isNull, reason: 'vérification oubliée');
  });
}
