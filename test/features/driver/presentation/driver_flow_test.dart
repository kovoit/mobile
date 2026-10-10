import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kovoit/core/config/demo_account.dart';
import 'package:kovoit/core/services/location_service.dart';
import 'package:kovoit/features/driver/presentation/screens/driver_trip_screen.dart';

import '../../../helpers/flows.dart';
import '../../../helpers/test_app.dart';

/// Texte dont les espaces (insécables ou non) sont normalisés : « 18 500 FCFA ».
Finder _amount(String text) => find.byWidgetPredicate(
      (w) => w is Text && w.data?.replaceAll(RegExp(r'\s'), ' ') == text,
    );

/// Laisse passer un sondage de l'écran de gestion du trajet (nouvelles demandes, actions).
Future<void> _waitForPoll(WidgetTester tester) async {
  await tester.pump(DriverTripScreen.pollInterval);
  await tester.pumpAndSettle();
}

Future<void> _scrollToTop(WidgetTester tester) async {
  await tester.drag(find.byType(ListView).first, const Offset(0, 3000));
  await tester.pumpAndSettle();
}

/// Publie Carrefour Franciscain → Université de Lomé à 07:30 (1 place), avec Avedji en 2e carrefour.
Future<void> _publishDemoTrip(WidgetTester tester) async {
  await choosePlace(tester, 'Carrefour, quartier, repère…', 'franc', 'Carrefour Franciscain');
  await choosePlace(tester, 'Où allez-vous ?', 'univ', 'Université de Lomé · Entrée sud');
  await scrollAndTap(tester, find.textContaining('Ajouter un carrefour'));
  await tester.enterText(find.byType(TextFormField), 'aved');
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Carrefour Avedji'));
  await tester.pumpAndSettle();
  await scrollAndTap(tester, find.text('Publier mon trajet'));
}

void main() {
  setUpAll(() => initializeDateFormatting('fr'));

  testWidgets('Espace Conducteur : économies, publication, prix recommandé, demandes reçues', (tester) async {
    await pumpKovoitApp(tester, env: TestEnv.driverSession());

    expect(find.text('Espace Conducteur'), findsOneWidget);
    expect(find.text('Publier'), findsOneWidget, reason: 'onglet en mode conducteur');
    expect(_amount('18 500 FCFA'), findsOneWidget);
    expect(find.text('Octobre · 24 places partagées'), findsOneWidget);
    expect(find.text('Passager'), findsNothing, reason: 'pas de sélecteur de mode sur cet écran');

    await choosePlace(tester, 'Carrefour, quartier, repère…', 'franc', 'Carrefour Franciscain');
    expect(find.text('1 / 3'), findsOneWidget, reason: 'le départ est proposé comme premier carrefour');
    await choosePlace(tester, 'Où allez-vous ?', 'univ', 'Université de Lomé · Entrée sud');
    await scrollTo(tester, find.text('Prix recommandé : 300 FCFA'));
    expect(find.text('Prix recommandé : 300 FCFA'), findsOneWidget);

    await scrollAndTap(tester, find.text('Publier mon trajet'));

    expect(find.text('Mon trajet'), findsOneWidget);
    expect(find.text('Demandes reçues'), findsOneWidget);
    expect(find.text('Afi Amégan'), findsOneWidget);
    expect(find.text('Kossi Akakpo'), findsOneWidget);
  });

  testWidgets('Accepter → code de départ (faux puis bon) → terminer le trajet → économies', (tester) async {
    final env = await pumpKovoitApp(tester, env: TestEnv.driverSession());
    await _publishDemoTrip(tester);

    await scrollAndTap(tester, find.widgetWithText(FilledButton, 'Accepter').first);
    expect(find.text('Demande acceptée.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Accepter'), findsNothing, reason: 'trajet complet');
    await _scrollToTop(tester);
    expect(find.text('0/1 places libres'), findsOneWidget);

    await scrollAndTap(tester, find.text('Saisir le code'));
    expect(find.text('Demandez à Afi son code à 4 chiffres, une fois à bord.'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, '1111');
    await tester.pumpAndSettle();
    expect(find.text('Code incorrect. 4 essais restants.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, DemoAccount.fakePassengerCode);
    await tester.pumpAndSettle();
    expect(find.text('Code de départ'), findsNothing, reason: 'boîte fermée après validation');
    expect(find.text('Afi est à bord. Bon trajet !'), findsOneWidget);

    // Laisse disparaître la SnackBar flottante, qui recouvre le bas de l'écran.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await scrollAndTap(tester, find.text('Terminer le trajet'));
    expect(find.text('Trajet terminé. Merci !'), findsOneWidget);
    await _scrollToTop(tester);
    expect(find.text('Terminé'), findsOneWidget);
    await scrollTo(tester, find.text('Économie : 300 FCFA'));
    expect(find.text('Économie : 300 FCFA'), findsOneWidget);
    // Appel hors widget : le délai simulé du backend ne s'écoule qu'en temps réel (runAsync).
    final savings = await tester.runAsync(env.driver.savings);
    expect(savings!['total'], 18800);
  });

  testWidgets('Absence : proposée après départ + tolérance, avec la position du conducteur', (tester) async {
    final env = await pumpKovoitApp(tester, env: TestEnv.driverSession());
    await _publishDemoTrip(tester);
    await scrollAndTap(tester, find.widgetWithText(FilledButton, 'Accepter').first);
    expect(find.text('Déclarer absent'), findsNothing, reason: 'trop tôt');

    env.now = DateTime.utc(2026, 10, 8, 7, 41);
    await _waitForPoll(tester);

    await scrollAndTap(tester, find.text('Déclarer absent'));
    await tester.tap(find.widgetWithText(TextButton, 'Déclarer absent'));
    await tester.pumpAndSettle();

    expect(env.location.calls, 1);
    expect(find.text('Absence enregistrée.'), findsOneWidget);
    await scrollTo(tester, find.text('Absent'));
    expect(find.text('Absent'), findsOneWidget);
  });

  testWidgets('Absence impossible sans localisation : message, rien n’est envoyé', (tester) async {
    final env = TestEnv.driverSession()..location.result = const LocationUnavailable('Activez la localisation de votre téléphone.');
    await pumpKovoitApp(tester, env: env);
    await _publishDemoTrip(tester);
    await scrollAndTap(tester, find.widgetWithText(FilledButton, 'Accepter').first);
    env.now = DateTime.utc(2026, 10, 8, 7, 41);
    await _waitForPoll(tester);

    await scrollAndTap(tester, find.text('Déclarer absent'));
    await tester.tap(find.widgetWithText(TextButton, 'Déclarer absent'));
    await tester.pumpAndSettle();

    expect(find.text('Activez la localisation de votre téléphone.'), findsOneWidget);
    expect(find.text('Absent'), findsNothing);
  });

  testWidgets('Mes trajets (mode conducteur) : trajet publié avec ses demandes en attente', (tester) async {
    await pumpKovoitApp(tester, env: TestEnv.driverSession());
    await _publishDemoTrip(tester);
    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mes trajets'));
    await tester.pumpAndSettle();
    expect(find.text('Trajets publiés'), findsOneWidget);
    expect(find.text('Adidogomé → Université de Lomé'), findsOneWidget);
    expect(find.text('Demandes'), findsOneWidget);
    expect(find.text('2'), findsOneWidget, reason: 'deux demandes en attente');
  });

  testWidgets('Publication refusée sans destination : erreurs sous les champs', (tester) async {
    await pumpKovoitApp(tester, env: TestEnv.driverSession());
    await scrollAndTap(tester, find.text('Publier mon trajet'));

    await scrollTo(tester, find.text('Choisissez votre point de départ.'));
    expect(find.text('Choisissez votre point de départ.'), findsOneWidget);
    expect(find.text('Choisissez votre destination.'), findsOneWidget);
    expect(find.text('Mon trajet'), findsNothing);
  });
}
