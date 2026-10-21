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

Future<void> _requestCode(WidgetTester tester, String email) async {
  await tester.enterText(_field('Adresse e-mail'), email);
  await _tapButton(tester, 'Recevoir le code');
}

Future<void> _enterCode(WidgetTester tester, String code) async {
  await tester.enterText(find.byType(TextField).first, code);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('fr'));

  testWidgets('Compte existant : e-mail → code → Rechercher', (tester) async {
    await pumpKovoitApp(tester);

    await _requestCode(tester, DemoAccount.email);
    expect(find.text('Vérification'), findsOneWidget);
    expect(find.text(DemoAccount.email), findsOneWidget);
    expect(find.textContaining('Renvoyer le code dans'), findsOneWidget);

    await _enterCode(tester, DemoAccount.otpCode);

    expect(find.text('Le même chemin, à plusieurs. Et moins cher.'), findsOneWidget);
  });

  testWidgets('Code faux : message d’erreur, reste sur l’écran du code', (tester) async {
    await pumpKovoitApp(tester);
    await _requestCode(tester, DemoAccount.email);

    await _enterCode(tester, '000000');

    expect(find.text('Code incorrect ou expiré.'), findsOneWidget);
    expect(find.text('Vérification'), findsOneWidget);
  });

  testWidgets('Validation locale de l’e-mail avant tout appel', (tester) async {
    await pumpKovoitApp(tester);

    await _tapButton(tester, 'Recevoir le code');

    expect(find.text("L'adresse e-mail est obligatoire."), findsOneWidget);
  });

  testWidgets('Modifier mon e-mail : retour à la saisie, adresse conservée', (tester) async {
    await pumpKovoitApp(tester);
    await _requestCode(tester, 'afi@exemple.com');

    await _tapButton(tester, 'Modifier mon e-mail');

    expect(find.text('Recevoir le code'), findsOneWidget);
    expect(find.text('afi@exemple.com'), findsOneWidget);
  });

  testWidgets('Nouveau compte : code → profil à compléter → Rechercher (KYC à faire)', (tester) async {
    await pumpKovoitApp(tester);
    await _requestCode(tester, 'afi@exemple.com');
    await _enterCode(tester, DemoAccount.otpCode);

    expect(find.text('Votre profil'), findsOneWidget);
    await _tapButton(tester, 'Continuer');
    expect(find.text('Le prénom est obligatoire.'), findsOneWidget);

    await tester.enterText(_field('Prénom'), 'Afi');
    await tester.enterText(_field('Nom'), 'Amégan');
    await tester.enterText(_field('Numéro de téléphone'), '91 23 45 67');
    await _tapButton(tester, 'Continuer');

    // Retour UX : pas de blocage KYC à l'inscription. L'accueil s'ouvre avec la restriction affichée.
    expect(find.text('Le même chemin, à plusieurs. Et moins cher.'), findsOneWidget);
    expect(find.text('Vérifiez votre identité'), findsOneWidget);
  });

  testWidgets('Profil : numéro déjà utilisé → erreur sous le champ', (tester) async {
    await pumpKovoitApp(tester);
    await _requestCode(tester, 'afi@exemple.com');
    await _enterCode(tester, DemoAccount.otpCode);

    await tester.enterText(_field('Prénom'), 'Afi');
    await tester.enterText(_field('Nom'), 'Amégan');
    await tester.enterText(_field('Numéro de téléphone'), '90 12 34 56'); // numéro du compte démo
    await _tapButton(tester, 'Continuer');

    expect(find.text('Ce numéro est déjà utilisé.'), findsOneWidget);
    expect(find.text('Votre profil'), findsOneWidget);
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
