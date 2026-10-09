import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../../helpers/test_app.dart';

/// Choisit un lieu dans l'écran « Point de départ » / « Destination » en tapant une partie de son nom.
Future<void> _choosePlace(WidgetTester tester, String field, String typed, String placeLabel) async {
  await scrollAndTap(tester, find.text(field));
  await tester.enterText(find.byType(TextFormField), typed);
  await tester.pump(const Duration(milliseconds: 350)); // anti-rebond de la saisie
  await tester.pumpAndSettle();
  await tester.tap(find.text(placeLabel));
  await tester.pumpAndSettle();
}

Future<void> _searchFranciscainToUniversity(WidgetTester tester) async {
  await _choosePlace(tester, 'Carrefour, quartier, repère…', 'franc', 'Carrefour Franciscain');
  await _choosePlace(tester, 'Où allez-vous ?', 'univ', 'Université de Lomé · Entrée sud');
  await scrollAndTap(tester, find.widgetWithText(FilledButton, 'Rechercher un trajet'));
}

void main() {
  setUpAll(() => initializeDateFormatting('fr'));

  testWidgets('Recherche → conducteurs disponibles → détail du trajet', (tester) async {
    await pumpKovoitApp(tester, env: TestEnv.demoSession());

    // Formulaire pré-rempli : date du jour et prochain quart d'heure.
    expect(find.text('08 oct. 2026'), findsOneWidget);
    expect(find.text('07:30'), findsOneWidget);

    await _searchFranciscainToUniversity(tester);

    expect(find.text('Conducteurs disponibles'), findsOneWidget);
    expect(find.text('Adidogomé → Université de Lomé · 08 oct. 2026'), findsOneWidget);
    expect(find.text('3 trajets en voiture'), findsOneWidget);
    expect(find.text('Départ dès 07:30'), findsOneWidget);
    expect(find.text('Koffi Mensah'), findsOneWidget);
    expect(find.text('Départ 07:30 · à votre départ'), findsOneWidget);
    expect(find.text('Adidogomé → Université de Lomé'), findsWidgets);

    await scrollAndTap(tester, find.text('Koffi Mensah'));

    expect(find.text('Détails & Réservation'), findsOneWidget);
    expect(find.text('Jeudi 08 octobre · 1 place en voiture'), findsOneWidget);
    expect(find.text('PRISE EN CHARGE · 07:30'), findsOneWidget);
    expect(find.text('Fiabilité 98 % · 128 trajets effectués'), findsOneWidget);
    expect(find.text('TG 4827 AU'), findsOneWidget);
    // Le total vient de l'API (prix_total), jamais d'un calcul dans l'app.
    await tester.scrollUntilVisible(find.text('Total à payer'), 150,
        scrollable: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first);
    expect(find.text('300 FCFA'), findsWidgets);
  });

  testWidgets('La recherche est mémorisée dans « Vos trajets récents »', (tester) async {
    final env = await pumpKovoitApp(tester, env: TestEnv.demoSession());
    await _searchFranciscainToUniversity(tester);

    expect(env.recentSearches.items, hasLength(1));
    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Vos trajets récents'), findsOneWidget);
    expect(find.text('Adidogomé → Université de Lomé'), findsOneWidget);
  });

  testWidgets('Validation : départ et destination obligatoires', (tester) async {
    await pumpKovoitApp(tester, env: TestEnv.demoSession());

    await scrollAndTap(tester, find.widgetWithText(FilledButton, 'Rechercher un trajet'));

    expect(find.text('Choisissez un point de départ.'), findsOneWidget);
    expect(find.text('Choisissez une destination.'), findsOneWidget);
    expect(find.text('Conducteurs disponibles'), findsNothing);
  });

  testWidgets('Aucun trajet à cette heure : message et retour au formulaire', (tester) async {
    final env = TestEnv.demoSession()..now = DateTime.utc(2026, 10, 8, 13, 50);
    await pumpKovoitApp(tester, env: env);

    await _searchFranciscainToUniversity(tester);

    expect(find.text('Aucun trajet ne correspond'), findsOneWidget);
    await scrollAndTap(tester, find.text('Modifier ma recherche'));
    expect(find.text('Carrefour Franciscain, Adidogomé'), findsOneWidget, reason: 'le formulaire garde les critères');
  });

  testWidgets('Sans KYC : recherche possible, réservation restreinte sur le détail', (tester) async {
    await pumpKovoitApp(tester, env: TestEnv.newUserSession());

    expect(find.text('Vérifiez votre identité'), findsOneWidget);
    await _searchFranciscainToUniversity(tester);
    expect(find.text('3 trajets en voiture'), findsOneWidget);

    await scrollAndTap(tester, find.text('Koffi Mensah'));
    await tester.scrollUntilVisible(find.text('Vérifiez votre identité'), 150,
        scrollable: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first);
    expect(find.text('Vérifiez votre identité'), findsOneWidget);
    expect(find.text('Réserver ma place'), findsNothing);
  });
}
