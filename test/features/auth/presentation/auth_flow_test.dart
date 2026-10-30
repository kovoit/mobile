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

Future<void> _login(WidgetTester tester, String email, String password) async {
  await tester.enterText(_field('Adresse e-mail'), email);
  await tester.enterText(_field('Mot de passe'), password);
  await _tapButton(tester, 'Se connecter');
}

Future<void> _enterCode(WidgetTester tester, String code) async {
  await tester.enterText(find.byType(TextField).first, code);
  await tester.pumpAndSettle();
}

const _home = 'Le même chemin, à plusieurs. Et moins cher.';

void main() {
  setUpAll(() => initializeDateFormatting('fr'));

  testWidgets('Compte de démo : e-mail + mot de passe → Rechercher', (tester) async {
    final env = await pumpKovoitApp(tester);

    await _login(tester, DemoAccount.email, DemoAccount.password);

    expect(find.text(_home), findsOneWidget);
    expect(env.storage.access, 'mock-access-1');
  });

  testWidgets('Mauvais mot de passe : message de l’API, reste sur la Connexion', (tester) async {
    final env = await pumpKovoitApp(tester);

    await _login(tester, DemoAccount.email, 'mauvais-mot-de-passe');

    expect(find.text('Email ou mot de passe incorrect.'), findsOneWidget);
    expect(find.text('Connectez-vous pour commencer votre trajet'), findsOneWidget);
    expect(env.storage.access, isNull);
  });

  testWidgets('Validation locale du format avant tout appel', (tester) async {
    await pumpKovoitApp(tester);

    await _tapButton(tester, 'Se connecter');

    expect(find.text("L'adresse e-mail est obligatoire."), findsOneWidget);
    expect(find.text('Le mot de passe est obligatoire.'), findsOneWidget);
  });

  testWidgets('Inscription → Vérification → Rechercher (KYC à faire)', (tester) async {
    final env = await pumpKovoitApp(tester);
    await _tapButton(tester, 'Créer un compte');
    expect(find.text('Créer un compte'), findsOneWidget); // titre de l'Inscription

    await tester.enterText(_field('Prénom'), 'Afi');
    await tester.enterText(_field('Nom'), 'Amégan');
    await tester.enterText(_field('Adresse e-mail'), 'afi@exemple.com');
    await tester.enterText(_field('Numéro de téléphone'), '90 12 34 56'); // numéro du compte démo (D-66)
    await tester.enterText(_field('Mot de passe'), 'Lome-Trajet-2026');
    await tester.enterText(_field('Confirmer le mot de passe'), 'Autre-chose-2026');
    await scrollAndTap(tester, find.text('J’accepte les conditions d’utilisation de Kovoit'));
    await _tapButton(tester, 'Créer mon compte');
    expect(find.text('Les mots de passe ne correspondent pas.'), findsOneWidget);

    await tester.enterText(_field('Confirmer le mot de passe'), 'Lome-Trajet-2026');
    await _tapButton(tester, 'Créer mon compte');

    expect(find.text('Vérification'), findsOneWidget);
    expect(find.text('afi@exemple.com'), findsOneWidget);
    expect(find.textContaining('Renvoyer le code dans'), findsOneWidget);
    expect(env.storage.access, isNull);

    await _enterCode(tester, '000000');
    expect(find.text('Code invalide ou expiré.'), findsOneWidget);

    await _enterCode(tester, DemoAccount.otpCode);
    expect(find.text(_home), findsOneWidget);
    expect(find.text('Vérifiez votre identité'), findsOneWidget);
  });

  testWidgets('Inscription : adresse déjà utilisée → message sous le champ e-mail', (tester) async {
    await pumpKovoitApp(tester);
    await _tapButton(tester, 'Créer un compte');

    await tester.enterText(_field('Prénom'), 'Afi');
    await tester.enterText(_field('Nom'), 'Amégan');
    await tester.enterText(_field('Adresse e-mail'), DemoAccount.email);
    await tester.enterText(_field('Numéro de téléphone'), '91 23 45 67');
    await tester.enterText(_field('Mot de passe'), 'Lome-Trajet-2026');
    await tester.enterText(_field('Confirmer le mot de passe'), 'Lome-Trajet-2026');
    await scrollAndTap(tester, find.text('J’accepte les conditions d’utilisation de Kovoit'));
    await _tapButton(tester, 'Créer mon compte');

    expect(find.text('Un compte existe déjà avec cette adresse e-mail.'), findsOneWidget);
    expect(find.text('Créer mon compte'), findsOneWidget);
  });

  testWidgets('Connexion d’une adresse non vérifiée → écran Vérification', (tester) async {
    final env = TestEnv();
    final id = env.backend.createUser(
      password: 'Lome-Trajet-2026',
      fields: {
        'prenom': 'Afi',
        'nom': 'Amégan',
        'email': 'afi@exemple.com',
        'telephone': '+22891234567',
        'email_verifie': false,
        'cgu_acceptees': true,
      },
    );
    await pumpKovoitApp(tester, env: env);

    await _login(tester, 'afi@exemple.com', 'Lome-Trajet-2026');

    expect(find.text('Vérification'), findsOneWidget);
    expect(find.text('afi@exemple.com'), findsOneWidget);
    await _enterCode(tester, DemoAccount.otpCode);
    expect(find.text(_home), findsOneWidget);
    expect(env.storage.access, 'mock-access-$id');
  });

  testWidgets('Mot de passe oublié : e-mail → code + nouveau mot de passe → Connexion avec succès', (tester) async {
    await pumpKovoitApp(tester);
    await _tapButton(tester, 'Mot de passe oublié ?');

    await tester.enterText(_field('Adresse e-mail'), DemoAccount.email);
    await _tapButton(tester, 'Recevoir le code');
    expect(find.text(DemoAccount.email), findsOneWidget);

    await _enterCode(tester, DemoAccount.otpCode);
    await tester.enterText(_field('Nouveau mot de passe'), 'Nouveau-Trajet-26');
    await tester.enterText(_field('Confirmer le mot de passe'), 'Nouveau-Trajet-26');
    await _tapButton(tester, 'Changer mon mot de passe');

    expect(find.text('Mot de passe modifié'), findsOneWidget);
    await _login(tester, DemoAccount.email, 'Nouveau-Trajet-26');
    expect(find.text(_home), findsOneWidget);
  });

  testWidgets('Compte ancien (D-69, D-80) : premier mot de passe, puis profil à compléter', (tester) async {
    await pumpKovoitApp(tester);
    await _tapButton(tester, 'Mot de passe oublié ?');
    await tester.enterText(_field('Adresse e-mail'), DemoAccount.legacyEmail);
    await _tapButton(tester, 'Recevoir le code');
    await _enterCode(tester, DemoAccount.otpCode);
    await tester.enterText(_field('Nouveau mot de passe'), 'Premier-Trajet-26');
    await tester.enterText(_field('Confirmer le mot de passe'), 'Premier-Trajet-26');
    await _tapButton(tester, 'Changer mon mot de passe');

    await _login(tester, DemoAccount.legacyEmail, 'Premier-Trajet-26');

    expect(find.text('Votre profil'), findsOneWidget);
    await tester.enterText(_field('Numéro de téléphone'), '90 12 34 56'); // même numéro qu'un autre compte (D-66)
    await scrollAndTap(tester, find.text('J’accepte les conditions d’utilisation de Kovoit'));
    await _tapButton(tester, 'Continuer');
    expect(find.text(_home), findsOneWidget);
  });

  testWidgets('Déconnexion depuis le Profil → connexion', (tester) async {
    final env = await pumpKovoitApp(tester, env: TestEnv.demoSession());

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    await _tapButton(tester, 'Se déconnecter');

    expect(find.text('Connectez-vous pour commencer votre trajet'), findsOneWidget);
    expect(env.storage.access, isNull);
  });

  testWidgets('Compte existant sans CGU acceptées : écran d’acceptation avant tout le reste', (tester) async {
    final env = TestEnv.demoSession();
    env.backend.updateUser(1, {'cgu_acceptees': false});
    await pumpKovoitApp(tester, env: env);

    expect(find.text('Conditions d’utilisation'), findsOneWidget);
    await scrollAndTap(tester, find.text('Lire les conditions d’utilisation'));
    expect(env.externalActions.urls.single, 'https://kovoittg.com/conditions-utilisation/');
    await _tapButton(tester, 'Continuer');
    expect(find.text('Cochez la case pour continuer.'), findsOneWidget);

    await scrollAndTap(tester, find.text('J’accepte les conditions d’utilisation de Kovoit'));
    await _tapButton(tester, 'Continuer');
    expect(find.text('Le même chemin, à plusieurs. Et moins cher.'), findsOneWidget);
  });
}
