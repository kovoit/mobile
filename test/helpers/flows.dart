import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_app.dart';

/// Parcours réutilisables des tests de widgets.

/// Choisit un lieu dans l'écran « Point de départ » / « Destination » en tapant une partie de son nom.
Future<void> choosePlace(WidgetTester tester, String fieldHint, String typed, String placeLabel) async {
  await scrollAndTap(tester, find.text(fieldHint));
  await tester.enterText(find.byType(TextFormField), typed);
  await tester.pump(const Duration(milliseconds: 350)); // anti-rebond de la saisie
  await tester.pumpAndSettle();
  await tester.tap(find.text(placeLabel));
  await tester.pumpAndSettle();
}

/// Recherche de démo : Carrefour Franciscain → Université de Lomé (3 trajets en voiture à 07:30).
Future<void> searchFranciscainToUniversity(WidgetTester tester) async {
  await choosePlace(tester, 'Carrefour, quartier, repère…', 'franc', 'Carrefour Franciscain');
  await choosePlace(tester, 'Où allez-vous ?', 'univ', 'Université de Lomé · Entrée sud');
  await scrollAndTap(tester, find.widgetWithText(FilledButton, 'Rechercher un trajet'));
}

/// Recherche puis ouverture du trajet de Koffi Mensah (07:30, 300 FCFA).
Future<void> openKoffiTrip(WidgetTester tester) async {
  await searchFranciscainToUniversity(tester);
  await scrollAndTap(tester, find.text('Koffi Mensah'));
}

/// Fait défiler la liste verticale de l'écran jusqu'à [finder] sans taper dessus.
Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isNotEmpty) return;
  await tester.scrollUntilVisible(
    finder,
    150,
    scrollable: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first,
  );
}

// ---------------------------------------------------------------- Authentification (M-004)

/// Champ de saisie d'un formulaire d'authentification, retrouvé par son libellé visible.
Finder authField(String label) => find.descendant(
      of: find.ancestor(of: find.text(label), matching: find.byType(Column)).first,
      matching: find.byType(TextFormField),
    );

/// Remplit l'écran Inscription (D-68). La case CGU n'est cochée que si [acceptTerms].
Future<void> fillRegistration(
  WidgetTester tester, {
  String prenom = 'Ama',
  String nom = 'Mensah',
  String email = 'ama.mensah@exemple.tg',
  String phone = '91 23 45 67',
  String password = 'Lome-Trajet-2026',
  String? confirmation,
  bool acceptTerms = true,
}) async {
  await tester.enterText(authField('Prénom'), prenom);
  await tester.enterText(authField('Nom'), nom);
  await tester.enterText(authField('Adresse e-mail'), email);
  await tester.enterText(authField('Numéro de téléphone'), phone);
  await tester.enterText(authField('Mot de passe'), password);
  await tester.enterText(authField('Confirmer le mot de passe'), confirmation ?? password);
  if (acceptTerms) await scrollAndTap(tester, find.text('J’accepte les conditions d’utilisation de Kovoit'));
}

/// Depuis la Connexion : ouvre l'Inscription, la remplit et touche « Créer mon compte ».
Future<void> registerFromLogin(WidgetTester tester, {String email = 'ama.mensah@exemple.tg', String password = 'Lome-Trajet-2026'}) async {
  await scrollAndTap(tester, find.text('Créer un compte'));
  await fillRegistration(tester, email: email, password: password);
  await scrollAndTap(tester, find.text('Créer mon compte'));
}

/// Saisit un code à 6 chiffres dans le premier champ de code de l'écran.
Future<void> enterEmailCode(WidgetTester tester, String code) async {
  await tester.enterText(find.byType(TextField).first, code);
  await tester.pumpAndSettle();
}

/// Connexion par e-mail + mot de passe depuis l'écran Connexion.
Future<void> loginWithPassword(WidgetTester tester, String email, String password) async {
  await tester.enterText(authField('Adresse e-mail'), email);
  await tester.enterText(authField('Mot de passe'), password);
  await scrollAndTap(tester, find.text('Se connecter'));
}
