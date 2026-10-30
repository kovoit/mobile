import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kovoit/core/network/api_exception.dart';
import 'package:kovoit/features/auth/domain/entities/otp_challenge.dart';
import 'package:kovoit/features/auth/domain/repositories/auth_repository.dart';
import 'package:kovoit/features/auth/presentation/providers/auth_providers.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/flows.dart';
import '../../../helpers/test_app.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

const _email = 'kofi@exemple.tg';
const _newPassword = 'Nouveau-Trajet-26';

Finder _errorUnder(String label, String message) =>
    find.descendant(of: authField(label), matching: find.text(message));

void main() {
  setUpAll(() => initializeDateFormatting('fr'));

  late _MockAuthRepository repository;

  setUp(() {
    repository = _MockAuthRepository();
    when(() => repository.restoreSession()).thenAnswer((_) async => null);
    when(() => repository.requestPasswordReset(any()))
        .thenAnswer((_) async => const OtpChallenge(email: _email, resendIn: Duration(seconds: 60)));
    when(() => repository.resetPassword(
          email: any(named: 'email'),
          code: any(named: 'code'),
          password: any(named: 'password'),
        )).thenAnswer((_) async {});
  });

  /// Connexion → « Mot de passe oublié ? » → e-mail → « Recevoir le code ».
  Future<TestEnv> openStepTwo(WidgetTester tester) async {
    final env = await pumpKovoitApp(tester, overrides: [authRepositoryProvider.overrideWithValue(repository)]);
    await scrollAndTap(tester, find.text('Mot de passe oublié ?'));
    await tester.enterText(authField('Adresse e-mail'), _email);
    await scrollAndTap(tester, find.text('Recevoir le code'));
    return env;
  }

  Future<void> fillStepTwo(WidgetTester tester, {String code = '123456', String? confirmation}) async {
    await enterEmailCode(tester, code);
    await tester.enterText(authField('Nouveau mot de passe'), _newPassword);
    await tester.enterText(authField('Confirmer le mot de passe'), confirmation ?? _newPassword);
  }

  Future<void> submit(WidgetTester tester) => scrollAndTap(tester, find.text('Changer mon mot de passe'));

  testWidgets('CA-073-4 · « Recevoir le code » ouvre l’étape 2 : code, nouveau mot de passe, confirmation, renvoi après 60 s', (tester) async {
    final env = await openStepTwo(tester);

    verify(() => repository.requestPasswordReset(_email)).called(1);
    expect(find.text('ÉTAPE 2 · NOUVEAU MOT DE PASSE'), findsOneWidget);
    expect(find.text(_email), findsOneWidget);
    expect(find.text('Code reçu par e-mail'), findsOneWidget);
    expect(authField('Nouveau mot de passe'), findsOneWidget);
    expect(authField('Confirmer le mot de passe'), findsOneWidget);
    expect(find.text('Renvoyer le code dans 01:00'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Renvoyer le code'), findsNothing);

    env.now = env.now.add(const Duration(seconds: 60));
    await tester.pump(const Duration(seconds: 60));
    await tester.tap(find.widgetWithText(TextButton, 'Renvoyer le code'));
    await tester.pumpAndSettle();

    verify(() => repository.requestPasswordReset(_email)).called(1);
    expect(find.text('Renvoyer le code dans 01:00'), findsOneWidget);
  });

  testWidgets('CA-073-4 · confirmation différente : signalée, aucun appel', (tester) async {
    await openStepTwo(tester);

    await fillStepTwo(tester, confirmation: 'Autre-Trajet-26');
    await submit(tester);

    expect(_errorUnder('Confirmer le mot de passe', 'Les mots de passe ne correspondent pas.'), findsOneWidget);
    verifyNever(() => repository.resetPassword(
          email: any(named: 'email'),
          code: any(named: 'code'),
          password: any(named: 'password'),
        ));
  });

  testWidgets('CA-073-4 · succès : retour à la Connexion avec un message de succès, aucun jeton', (tester) async {
    final env = await openStepTwo(tester);

    await fillStepTwo(tester);
    await submit(tester);

    verify(() => repository.resetPassword(email: _email, code: '123456', password: _newPassword)).called(1);
    expect(find.text('Connectez-vous pour commencer votre trajet'), findsOneWidget);
    expect(find.text('Mot de passe modifié'), findsOneWidget);
    expect(find.text('Connectez-vous avec votre nouveau mot de passe.'), findsOneWidget);
    expect(env.storage.access, isNull);
  });

  testWidgets('code refusé (400 CODE_OTP_INVALIDE) : message de l’API, reste à l’étape 2', (tester) async {
    when(() => repository.resetPassword(
          email: any(named: 'email'),
          code: any(named: 'code'),
          password: any(named: 'password'),
        )).thenThrow(ApiException.fromResponse(400, {
      'statut': 'failed',
      'message': 'Code invalide ou expiré.',
      'reponse': {'code': 'CODE_OTP_INVALIDE', 'erreurs': <String, dynamic>{}},
    }));
    await openStepTwo(tester);

    await fillStepTwo(tester, code: '000000');
    await submit(tester);

    await scrollTo(tester, find.text('Code invalide ou expiré.'));
    expect(find.text('Code invalide ou expiré.'), findsOneWidget);
    expect(find.text('Mot de passe modifié'), findsNothing);
  });
}
