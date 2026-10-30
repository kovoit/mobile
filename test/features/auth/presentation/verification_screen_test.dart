import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kovoit/core/config/demo_account.dart';
import 'package:kovoit/features/auth/domain/access_policy.dart';
import 'package:kovoit/features/kyc/presentation/widgets/access_required_card.dart';

import '../../../helpers/flows.dart';
import '../../../helpers/test_app.dart';

const _email = 'ama.mensah@exemple.tg';
const _verificationKey = 'verification_email:$_email';

/// Bouton « Renvoyer le code » actif (sinon seul le compte à rebours est affiché).
Finder get _resendButton => find.widgetWithText(TextButton, 'Renvoyer le code');

Finder get _verticalList =>
    find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first;

String _textOf(WidgetTester tester, String label) => tester.widget<TextFormField>(authField(label)).controller!.text;

/// Avance l'horloge des tests (celle du compte à rebours) et laisse passer le temps des minuteries.
Future<void> _wait(WidgetTester tester, TestEnv env, Duration duration) async {
  env.now = env.now.add(duration);
  await tester.pump(duration);
}

void main() {
  setUpAll(() => initializeDateFormatting('fr'));

  testWidgets('CA-071-5 · adresse affichée ; « Renvoyer le code » inactif 60 s puis actif', (tester) async {
    final env = await pumpKovoitApp(tester);
    await registerFromLogin(tester, email: _email);

    expect(find.text('Vérification'), findsOneWidget);
    expect(find.text(_email), findsOneWidget);
    expect(find.text('Renvoyer le code dans 01:00'), findsOneWidget);
    expect(_resendButton, findsNothing);
    final firstSent = env.backend.codesSent[_verificationKey];
    expect(firstSent, env.now);

    await _wait(tester, env, const Duration(seconds: 30));
    expect(find.text('Renvoyer le code dans 00:30'), findsOneWidget);
    expect(_resendButton, findsNothing);

    await _wait(tester, env, const Duration(seconds: 30));
    expect(find.textContaining('Renvoyer le code dans'), findsNothing);
    expect(_resendButton, findsOneWidget);

    await tester.tap(_resendButton);
    await tester.pumpAndSettle();
    expect(env.backend.codesSent[_verificationKey], firstSent!.add(const Duration(seconds: 60)),
        reason: 'un nouveau code part à la même adresse');
    expect(find.text('Renvoyer le code dans 01:00'), findsOneWidget, reason: 'nouveau compte à rebours');
    expect(_resendButton, findsNothing);
  });

  testWidgets('CA-071-5 / D-75 · « Modifier mon e-mail » ramène à l’Inscription pour une autre adresse', (tester) async {
    await pumpKovoitApp(tester);
    await registerFromLogin(tester, email: _email);

    await tester.tap(find.text('Modifier mon e-mail'));
    await tester.pumpAndSettle();

    // Retour sur l'Inscription, restée défilée jusqu'au bouton : on remonte au titre.
    await tester.scrollUntilVisible(find.text('Créer un compte'), -150, scrollable: _verticalList);
    expect(find.text('Créer un compte'), findsOneWidget); // titre de l'Inscription
    expect(_textOf(tester, 'Prénom'), 'Ama', reason: 'identité gardée');
    expect(_textOf(tester, 'Adresse e-mail'), _email);
    expect(_textOf(tester, 'Mot de passe'), isEmpty, reason: 'mot de passe redemandé');
    expect(_textOf(tester, 'Confirmer le mot de passe'), isEmpty);

    await tester.enterText(authField('Adresse e-mail'), 'ama.k@exemple.tg');
    await tester.enterText(authField('Mot de passe'), 'Lome-Trajet-2026');
    await tester.enterText(authField('Confirmer le mot de passe'), 'Lome-Trajet-2026');
    await scrollAndTap(tester, find.text('Créer mon compte'));

    expect(find.text('Vérification'), findsOneWidget);
    expect(find.text('ama.k@exemple.tg'), findsOneWidget);
    expect(find.text(_email), findsNothing);
  });

  testWidgets('D-75 · « Modifier mon e-mail » après une connexion non vérifiée ouvre aussi l’Inscription', (tester) async {
    final env = TestEnv();
    env.backend.createUser(
      password: 'Lome-Trajet-2026',
      fields: {
        'prenom': 'Ama',
        'nom': 'Mensah',
        'email': _email,
        'telephone': '+22891234567',
        'email_verifie': false,
        'cgu_acceptees': true,
      },
    );
    await pumpKovoitApp(tester, env: env);
    await loginWithPassword(tester, _email, 'Lome-Trajet-2026');
    expect(find.text('Vérification'), findsOneWidget);

    await tester.tap(find.text('Modifier mon e-mail'));
    await tester.pumpAndSettle();

    expect(find.text('Créer un compte'), findsOneWidget); // titre de l'Inscription
    expect(find.text('Vérification'), findsNothing);
  });

  testWidgets('CA-071-5 · le bon code ouvre l’accueil avec la carte « accès restreint »', (tester) async {
    final env = await pumpKovoitApp(tester);
    await registerFromLogin(tester, email: _email);

    await enterEmailCode(tester, DemoAccount.otpCode);

    expect(find.text('Le même chemin, à plusieurs. Et moins cher.'), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) => w is AccessRequiredCard && w.denial == AccessDenial.kycPassagerMissing),
      findsOneWidget,
    );
    expect(find.text('Vérifiez votre identité'), findsOneWidget);
    expect(find.text('Votre profil'), findsNothing, reason: 'CA-003-4 : jamais « Profil à compléter »');
    expect(env.storage.access, isNotNull);
  });
}
