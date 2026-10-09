import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kovoit/core/config/demo_account.dart';

import '../../../helpers/test_app.dart';

Finder _field(String label) => find.descendant(
      of: find.ancestor(of: find.text(label), matching: find.byType(Column)).first,
      matching: find.byType(TextFormField),
    );

Future<void> _tapButton(WidgetTester tester, String label) => scrollAndTap(tester, find.text(label));

void main() {
  setUpAll(() => initializeDateFormatting('fr'));

  testWidgets('Connexion e-mail + mot de passe → Rechercher', (tester) async {
    await pumpKovoitApp(tester);

    await tester.enterText(_field('Email'), DemoAccount.email);
    await tester.enterText(_field('Mot de passe'), DemoAccount.password);
    await _tapButton(tester, 'Se connecter');

    expect(find.text('Le même chemin, à plusieurs. Et moins cher.'), findsOneWidget);
  });

  testWidgets('Connexion refusée : message d’erreur, reste sur l’écran', (tester) async {
    await pumpKovoitApp(tester);

    await tester.enterText(_field('Email'), DemoAccount.email);
    await tester.enterText(_field('Mot de passe'), 'mauvais-mdp');
    await _tapButton(tester, 'Se connecter');

    expect(find.text('Email ou mot de passe incorrect.'), findsOneWidget);
    expect(find.text('Connectez-vous pour commencer votre trajet'), findsOneWidget);
  });

  testWidgets('Validation locale avant tout appel', (tester) async {
    await pumpKovoitApp(tester);

    await _tapButton(tester, 'Se connecter');

    expect(find.text("L'adresse e-mail est obligatoire."), findsOneWidget);
    expect(find.text('Le mot de passe est obligatoire.'), findsOneWidget);
  });

  testWidgets('Inscription → Vérification SMS → code faux puis bon → Rechercher', (tester) async {
    await pumpKovoitApp(tester);
    await tester.tap(find.text('Inscription'));
    await tester.pumpAndSettle();

    await tester.enterText(_field('Nom complet'), 'Afi Amégan');
    await tester.enterText(_field('Adresse e-mail'), 'afi@exemple.com');
    await tester.enterText(_field('Numéro de téléphone'), '91 23 45 67');
    await tester.enterText(_field('Mot de passe'), 'motdepasse');

    // CGU non acceptées : bloqué.
    await _tapButton(tester, 'Créer mon compte');
    expect(find.text('Vous devez accepter les conditions pour créer un compte.'), findsOneWidget);

    await tester.tap(find.byType(Checkbox));
    await _tapButton(tester, 'Créer mon compte');

    expect(find.text('Vérification SMS'), findsOneWidget);
    expect(find.text('+228 91 23 45 67'), findsOneWidget);
    expect(find.textContaining('Renvoyer le code dans'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '000000');
    await tester.pumpAndSettle();
    expect(find.text('Code invalide ou expiré.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, DemoAccount.otpCode);
    await tester.pumpAndSettle();

    // Retour UX : plus de blocage KYC à l'inscription. L'accueil s'ouvre avec la restriction affichée.
    expect(find.text('Le même chemin, à plusieurs. Et moins cher.'), findsOneWidget);
    expect(find.text('Vérifiez votre identité'), findsOneWidget);
  });

  testWidgets('Inscription avec un e-mail déjà utilisé : erreur sous le champ', (tester) async {
    await pumpKovoitApp(tester);
    await tester.tap(find.text('Inscription'));
    await tester.pumpAndSettle();

    await tester.enterText(_field('Nom complet'), 'Kodjo Mensah');
    await tester.enterText(_field('Adresse e-mail'), DemoAccount.email);
    await tester.enterText(_field('Numéro de téléphone'), '99 88 77 66');
    await tester.enterText(_field('Mot de passe'), 'motdepasse');
    await tester.tap(find.byType(Checkbox));
    await _tapButton(tester, 'Créer mon compte');

    expect(find.text('Un compte existe déjà avec cet e-mail.'), findsOneWidget);
    expect(find.text('Créez votre compte'), findsOneWidget);
  });

  testWidgets('Google sans numéro → saisie du numéro → Vérification SMS', (tester) async {
    await pumpKovoitApp(tester);

    await _tapButton(tester, 'Continuer avec Google');
    expect(find.text('Votre numéro'), findsOneWidget);

    await tester.enterText(_field('Numéro de téléphone'), '70 11 22 33');
    await _tapButton(tester, 'Recevoir le code');

    expect(find.text('Vérification SMS'), findsOneWidget);
    expect(find.text('+228 70 11 22 33'), findsOneWidget);
  });

  testWidgets('Déconnexion depuis le Profil → connexion', (tester) async {
    final env = await pumpKovoitApp(tester, env: TestEnv.demoSession());

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    await _tapButton(tester, 'Se déconnecter');

    expect(find.text('Connectez-vous pour commencer votre trajet'), findsOneWidget);
    expect(env.storage.access, isNull);
  });
}
