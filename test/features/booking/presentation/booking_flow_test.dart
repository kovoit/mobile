import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kovoit/features/booking/presentation/screens/booking_screen.dart';
import 'package:kovoit/features/booking/presentation/widgets/departure_code_card.dart';

import '../../../helpers/flows.dart';
import '../../../helpers/test_app.dart';

String _bookingId(TestEnv env) => env.backend.bookings.keys.last;

void main() {
  setUpAll(() => initializeDateFormatting('fr'));

  testWidgets('Réservation par le portefeuille : demande → acceptation → code de départ → partage', (tester) async {
    final env = await pumpKovoitApp(tester, env: TestEnv.demoSession()); // 2 000 F disponibles
    await openKoffiTrip(tester);

    await scrollTo(tester, find.text('Payé avec mon portefeuille'));
    expect(find.text('Payé avec mon portefeuille'), findsOneWidget);
    expect(find.textContaining('Il manque'), findsNothing);
    await scrollAndTap(tester, find.text('Réserver ma place'));

    expect(find.text('Demande envoyée'), findsOneWidget);
    expect(find.text('En attente'), findsOneWidget);
    expect(find.byType(DepartureCodeCard), findsNothing, reason: 'pas de code avant acceptation');
    expect(env.wallet.balanceOf(1)['bloque'], 300, reason: 'montant réservé sur le portefeuille');

    // Le conducteur accepte → code de départ affiché au passager.
    await env.bookings.simulateDriverAccepts(_bookingId(env));
    await tester.pump(BookingScreen.statusPollInterval);
    await tester.pumpAndSettle();

    expect(find.text('Suivi du trajet & Code de départ'), findsOneWidget);
    expect(find.byType(DepartureCodeCard), findsOneWidget);
    final code = env.backend.bookings[_bookingId(env)]!['code_depart'] as String;
    expect(find.textContaining(code, findRichText: true), findsOneWidget);

    await scrollAndTap(tester, find.text('Partager mon trajet'));
    expect(env.externalActions.shares.single, contains('/api/v1/partage/'));
  });

  testWidgets('Solde insuffisant : recharge Mixx (PayGate) puis réservation', (tester) async {
    final env = TestEnv.demoSession();
    env.wallet.write(1, 'retrait', 1900); // il reste 100 F
    await pumpKovoitApp(tester, env: env);
    await openKoffiTrip(tester);

    await scrollTo(tester, find.text('Il manque 200 FCFA sur votre portefeuille.'));
    expect(find.text('Il manque 200 FCFA sur votre portefeuille.'), findsOneWidget);
    final reserve = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Réserver ma place'));
    expect(reserve.onPressed, isNull, reason: 'réservation bloquée tant que le solde ne suffit pas');

    // Recharge suggérée : au moins la recharge minimale (500 F), payée par Mixx.
    await scrollAndTap(tester, find.text('Recharger 500 FCFA'));
    expect(find.text('Recharger mon portefeuille'), findsOneWidget);
    await tester.tap(find.text('Mixx'));
    await tester.pump();
    await tester.tap(find.text('Payer'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 5));
    expect(find.textContaining('Validez le paiement sur votre téléphone'), findsOneWidget);

    // PayGate confirme (second contrôle) : le portefeuille est crédité.
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
    expect(find.text('500 FCFA ajoutés à votre portefeuille.'), findsOneWidget);
    expect(env.wallet.balanceOf(1)['disponible'], 600);

    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Il manque'), findsNothing);
    await scrollAndTap(tester, find.text('Réserver ma place'));
    expect(find.text('Demande envoyée'), findsOneWidget);
  });

  testWidgets('Annulation après acceptation : tardive, montant rendu', (tester) async {
    final env = await pumpKovoitApp(tester, env: TestEnv.demoSession());
    await openKoffiTrip(tester);
    await scrollAndTap(tester, find.text('Réserver ma place'));
    await env.bookings.simulateDriverAccepts(_bookingId(env));
    await tester.drag(find.byType(ListView).first, const Offset(0, 400)); // tirer pour rafraîchir
    await tester.pumpAndSettle();

    await scrollAndTap(tester, find.widgetWithText(OutlinedButton, 'Annuler'));
    expect(find.textContaining('compte comme tardive'), findsOneWidget);
    await tester.tap(find.text('Annuler la réservation'));
    await tester.pumpAndSettle();

    expect(find.text('Réservation annulée'), findsOneWidget);
    expect(find.text('Annulation tardive.'), findsOneWidget, reason: '07:20, départ 07:30 : moins de 30 min');
    expect(find.widgetWithText(OutlinedButton, 'Annuler'), findsNothing);
    expect(find.text('Rechercher un autre trajet'), findsOneWidget);
    expect(env.wallet.balanceOf(1)['disponible'], 2000);
  });

  testWidgets('Refus du conducteur', (tester) async {
    final env = await pumpKovoitApp(tester, env: TestEnv.demoSession());
    await openKoffiTrip(tester);
    await scrollAndTap(tester, find.text('Réserver ma place'));

    await env.bookings.simulateDriverRefuses(_bookingId(env));
    await tester.drag(find.byType(ListView).first, const Offset(0, 400)); // tirer pour rafraîchir
    await tester.pumpAndSettle();

    expect(find.text('Demande refusée'), findsOneWidget);
    expect(find.text('Refusée'), findsOneWidget);
  });

  testWidgets('Mes trajets : la réservation apparaît, et le trajet renvoie vers son suivi', (tester) async {
    await pumpKovoitApp(tester, env: TestEnv.demoSession());
    await openKoffiTrip(tester);
    await scrollAndTap(tester, find.text('Réserver ma place'));
    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pumpAndSettle();

    // Retour sur les résultats : rouvrir le même trajet propose « Voir ma réservation ».
    await scrollAndTap(tester, find.text('Koffi Mensah'));
    expect(find.text('Voir ma réservation'), findsOneWidget);
    await scrollTo(tester, find.text('Vous avez déjà une demande sur ce trajet.'));
    expect(find.text('Vous avez déjà une demande sur ce trajet.'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mes trajets'));
    await tester.pumpAndSettle();
    expect(find.text('À venir'), findsOneWidget);
    expect(find.text('Carrefour Franciscain → Université de Lomé'), findsOneWidget);
    expect(find.text('En attente'), findsOneWidget);
    expect(find.text('Portefeuille'), findsOneWidget);
  });

  testWidgets('Mes trajets vide : invitation à rechercher', (tester) async {
    await pumpKovoitApp(tester, env: TestEnv.demoSession());
    await tester.tap(find.text('Mes trajets'));
    await tester.pumpAndSettle();

    expect(find.text('Aucune réservation pour l’instant'), findsOneWidget);
  });
}
