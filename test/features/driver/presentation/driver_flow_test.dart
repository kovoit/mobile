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

  testWidgets('Espace Conducteur : économies, publication, prix fixé par Kovoit, demandes reçues', (tester) async {
    await pumpKovoitApp(tester, env: TestEnv.driverSession());

    expect(find.text('Espace Conducteur'), findsOneWidget);
    expect(find.text('Publier'), findsOneWidget, reason: 'onglet en mode conducteur');
    expect(_amount('18 500 FCFA'), findsOneWidget);
    expect(find.textContaining('Depuis le début'), findsOneWidget);
    expect(find.text('Passager'), findsNothing, reason: 'pas de sélecteur de mode sur cet écran');

    await choosePlace(tester, 'Carrefour, quartier, repère…', 'franc', 'Carrefour Franciscain');
    expect(find.text('1 / 3'), findsOneWidget, reason: 'le départ est proposé comme premier carrefour');
    await choosePlace(tester, 'Où allez-vous ?', 'univ', 'Université de Lomé · Entrée sud');
    // Prix calculé par Kovoit (API d'estimation) dès que départ et destination sont choisis
    await scrollTo(tester, find.text('Prix calculé par Kovoit'));
    expect(find.text('Prix calculé par Kovoit'), findsOneWidget);
    await scrollTo(tester, find.text('Commission Kovoit (15 %) par place'));
    expect(find.text('Commission Kovoit (15 %) par place'), findsOneWidget);

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
    expect(find.text('Code de départ incorrect (4 essai(s) restant(s)).'), findsOneWidget);

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
    // Appel hors widget : le délai simulé du backend ne s'écoule qu'en temps réel (runAsync).
    final savings = await tester.runAsync(env.driver.savings);
    final demande = ((env.backend.driverTrips.values.last['demandes'] as List).first as Map);
    final net = demande['net_conducteur'] as int;
    expect(net + (demande['commission'] as int), demande['prix'], reason: 'payé = commission + net');
    expect(savings!['mois_en_cours'], 18500 + net, reason: 'le conducteur touche le net');
  });

  testWidgets('Absence : refusée par le serveur avant départ + tolérance, puis enregistrée', (tester) async {
    final env = await pumpKovoitApp(tester, env: TestEnv.driverSession());
    await _publishDemoTrip(tester);
    await scrollAndTap(tester, find.widgetWithText(FilledButton, 'Accepter').first);
    final avant = env.location.calls; // le partage de position a déjà relevé la position

    // Trop tôt : le délai de tolérance est un paramètre serveur, c'est lui qui refuse.
    await scrollAndTap(tester, find.text('Déclarer absent'));
    await tester.tap(find.widgetWithText(TextButton, 'Déclarer absent'));
    await tester.pumpAndSettle();
    expect(find.textContaining("après l'heure de départ"), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    env.now = DateTime.utc(2026, 10, 8, 7, 41);
    await _waitForPoll(tester);

    await scrollAndTap(tester, find.text('Déclarer absent'));
    await tester.tap(find.widgetWithText(TextButton, 'Déclarer absent'));
    await tester.pumpAndSettle();

    expect(env.location.calls, avant + 2, reason: 'position relevée à chaque tentative, refusée puis acceptée');
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
    expect(find.text('Carrefour Franciscain → Université de Lomé'), findsOneWidget);
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

  testWidgets('Partager mon trajet : suivi dès un passager accepté, une position toutes les 30 s', (tester) async {
    final env = await pumpKovoitApp(tester, env: TestEnv.driverSession());
    await _publishDemoTrip(tester);
    final tripId = env.backend.driverTrips.keys.last;
    expect(find.text('Position partagée pendant le trajet'), findsNothing, reason: 'aucun passager accepté');
    expect(env.location.trackings, 0);

    await scrollAndTap(tester, find.widgetWithText(FilledButton, 'Accepter').first);
    await _scrollToTop(tester);
    expect(find.text('Position partagée pendant le trajet'), findsOneWidget);
    expect(env.location.trackings, 1);

    Future<void> position(double lat) async {
      env.location.emit(LocationFound(lat, 1.1650));
      await tester.pump(const Duration(seconds: 1)); // latence simulée du backend
      await tester.pump();
    }

    await position(6.1661);
    expect(env.backend.driverTrips[tripId]!['position_lat'], 6.1661);
    await position(6.1662); // moins de 30 s après : pas envoyée
    expect(env.backend.driverTrips[tripId]!['position_lat'], 6.1661);
    env.now = env.now.add(DriverTripScreen.positionInterval);
    await position(6.1663);
    expect(env.backend.driverTrips[tripId]!['position_lat'], 6.1663);
  });

  testWidgets('Partager mon trajet : localisation refusée → bandeau, aucune demande en boucle', (tester) async {
    final env = await pumpKovoitApp(tester, env: TestEnv.driverSession());
    env.location.result = const LocationUnavailable('Autorisez Kovoit à accéder à votre position.');
    await _publishDemoTrip(tester);

    await scrollAndTap(tester, find.widgetWithText(FilledButton, 'Accepter').first);
    await _scrollToTop(tester);
    expect(find.text('Position non partagée'), findsOneWidget);

    await _waitForPoll(tester);
    expect(env.location.trackings, 1, reason: 'pas de nouvelle demande d’autorisation à chaque relecture');
  });

  testWidgets('Partager mon trajet : continue après la fermeture de l’écran du trajet', (tester) async {
    final env = await pumpKovoitApp(tester, env: TestEnv.driverSession());
    await _publishDemoTrip(tester);
    final tripId = env.backend.driverTrips.keys.last;
    await scrollAndTap(tester, find.widgetWithText(FilledButton, 'Accepter').first);

    await tester.tap(find.byIcon(Icons.chevron_left_rounded)); // l'écran du trajet est fermé
    await tester.pumpAndSettle();
    env.location.emit(const LocationFound(6.1700, 1.1700));
    await tester.pump(const Duration(seconds: 1)); // latence simulée du backend
    await tester.pump();

    expect(env.backend.driverTrips[tripId]!['position_lat'], 6.1700);
  });

  testWidgets('Prix indisponible (API injoignable) : message clair, aucun montant affiché', (tester) async {
    final env = await pumpKovoitApp(tester, env: TestEnv.driverSession());
    env.driver.estimationUnavailable = true;
    await choosePlace(tester, 'Carrefour, quartier, repère…', 'franc', 'Carrefour Franciscain');
    await choosePlace(tester, 'Où allez-vous ?', 'univ', 'Université de Lomé · Entrée sud');

    await scrollTo(tester, find.text('Prix indisponible pour le moment'));
    expect(find.text('Prix indisponible pour le moment'), findsOneWidget);
    expect(find.text('Prix calculé par Kovoit'), findsNothing);
    expect(find.textContaining('Commission Kovoit'), findsNothing);
  });
}
