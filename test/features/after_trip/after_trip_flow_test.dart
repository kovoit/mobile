import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kovoit/core/config/demo_account.dart';

import '../../helpers/flows.dart';
import '../../helpers/test_app.dart';

String _lastBooking(TestEnv env) => env.backend.bookings.keys.last;

/// Réserve le trajet de Koffi puis fait jouer au conducteur : accepter, prise en charge, fin.
Future<String> _bookAndFinish(WidgetTester tester, TestEnv env) async {
  await openKoffiTrip(tester);
  await scrollAndTap(tester, find.text('Réserver ma place'));
  final id = _lastBooking(env);
  await tester.runAsync(() async {
    await env.bookings.simulateDriverAccepts(id);
    await env.bookings.simulatePickup(id);
    await env.bookings.simulateTripFinished(id);
  });
  await tester.drag(find.byType(ListView).first, const Offset(0, 500)); // tirer pour rafraîchir
  await tester.pumpAndSettle();
  return id;
}

void main() {
  setUpAll(() => initializeDateFormatting('fr'));

  testWidgets('Passager : confirmer son arrivée puis noter le conducteur', (tester) async {
    final env = await pumpKovoitApp(tester, env: TestEnv.demoSession());
    final id = await _bookAndFinish(tester, env);

    expect(find.text('Vous êtes arrivé ?'), findsOneWidget);
    await scrollAndTap(tester, find.text('Confirmer mon arrivée'));

    // La feuille de notation s'ouvre d'elle-même après la confirmation.
    expect(find.text('Notez Koffi'), findsOneWidget);
    await tester.tap(find.text('Envoyer ma note'));
    await tester.pumpAndSettle();
    expect(find.text('Choisissez une note.'), findsOneWidget);

    await tester.tap(find.byTooltip('4 étoiles'));
    await tester.pumpAndSettle();
    expect(find.text('Bien'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Un commentaire ? (facultatif)'), 'Très ponctuel.');
    await tester.tap(find.text('Envoyer ma note'));
    await tester.pumpAndSettle();

    expect(find.text('Merci pour votre note !'), findsOneWidget);
    expect(find.text('Trajet terminé'), findsOneWidget);
    expect(find.text('Noter Koffi'), findsNothing);
    expect(env.backend.ratings, contains('$id:1'));
  });

  testWidgets('Passager : signaler un problème après le trajet → litige', (tester) async {
    final env = await pumpKovoitApp(tester, env: TestEnv.demoSession());
    final id = await _bookAndFinish(tester, env);

    await scrollAndTap(tester, find.text('Signaler un problème'));
    expect(find.text('Trajet avec Koffi. Votre signalement est transmis à l’équipe Kovoit.'), findsOneWidget);

    await scrollAndTap(tester, find.text('Envoyer le signalement'));
    expect(find.text('Choisissez un motif et décrivez le problème.'), findsOneWidget);

    await scrollAndTap(tester, find.text('Retard important'));
    await tester.enterText(find.byType(TextField), 'Le conducteur est arrivé 25 minutes en retard.');
    await scrollAndTap(tester, find.text('Envoyer le signalement'));

    expect(find.text('Signalement en cours'), findsOneWidget);
    expect(find.text('Litige'), findsOneWidget);
    expect(find.text('Confirmer mon arrivée'), findsNothing);
    expect(env.backend.reports['$id:1'], 'Retard important — Le conducteur est arrivé 25 minutes en retard.');
  });

  testWidgets('Push : appareil enregistré, push touché → écran de la réservation', (tester) async {
    final env = await pumpKovoitApp(tester, env: TestEnv.demoSession());
    expect(env.push.starts, 1, reason: 'push démarré pour un utilisateur vérifié');

    env.push.emitToken('fcm-token-123');
    await tester.pumpAndSettle();
    expect(env.backend.devices['fcm-token-123'], 1);

    await openKoffiTrip(tester);
    await scrollAndTap(tester, find.text('Réserver ma place'));
    final id = _lastBooking(env);
    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pumpAndSettle();

    // Le backend envoie `reservation_id` avec chaque push.
    env.push.emitOpened({'reservation_id': id});
    await tester.pumpAndSettle();
    expect(find.text('Demande envoyée'), findsOneWidget);
  });

  testWidgets('Conducteur : noter le passager après le trajet', (tester) async {
    final env = await pumpKovoitApp(tester, env: TestEnv.driverSession());
    await choosePlace(tester, 'Carrefour, quartier, repère…', 'franc', 'Carrefour Franciscain');
    await choosePlace(tester, 'Où allez-vous ?', 'univ', 'Université de Lomé · Entrée sud');
    await scrollAndTap(tester, find.text('Publier mon trajet'));

    final tripId = env.backend.driverTrips.keys.last;
    final requestId = ((env.backend.driverTrips[tripId]!['demandes'] as List).first as Map)['id'] as String;
    await tester.runAsync(() async {
      await env.driver.accept(requestId);
      await env.driver.submitCode(requestId, DemoAccount.fakePassengerCode);
      await env.driver.finishTrip(tripId);
    });
    await tester.drag(find.byType(ListView).first, const Offset(0, 500));
    await tester.pumpAndSettle();

    await scrollAndTap(tester, find.widgetWithText(OutlinedButton, 'Noter'));
    expect(find.text('Notez Afi'), findsOneWidget);
    await tester.tap(find.byTooltip('5 étoiles'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Envoyer ma note'));
    await tester.pumpAndSettle();

    expect(find.text('Merci pour votre note !'), findsOneWidget);
    expect(env.backend.ratings, contains('$requestId:2'));
    expect(find.widgetWithText(OutlinedButton, 'Noter'), findsNothing);
  });
}
