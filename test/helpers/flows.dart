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
