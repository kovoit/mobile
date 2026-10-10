import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kovoit/features/booking/presentation/screens/booking_screen.dart';
import 'package:kovoit/features/booking/presentation/widgets/departure_code_card.dart';

import '../../../helpers/flows.dart';
import '../../../helpers/test_app.dart';

int _bookingId(TestEnv env) => env.backend.bookings.keys.last;

void main() {
  setUpAll(() => initializeDateFormatting('fr'));

  testWidgets('Réservation Flooz : demande → acceptation → code de départ → paiement → partage', (tester) async {
    final env = await pumpKovoitApp(tester, env: TestEnv.demoSession());
    await openKoffiTrip(tester);

    // CA2 : choix du paiement puis demande de place.
    await scrollAndTap(tester, find.text('Mobile Money'));
    expect(find.textContaining('Paiement Flooz (Moov Africa)'), findsOneWidget);
    await scrollAndTap(tester, find.text('Réserver ma place'));

    expect(find.text('Demande envoyée'), findsOneWidget);
    expect(find.text('En attente'), findsOneWidget);
    expect(find.byType(DepartureCodeCard), findsNothing, reason: 'pas de code avant acceptation');

    // CA3 : le conducteur accepte → code de départ affiché au passager.
    await env.bookings.simulateDriverAccepts(_bookingId(env));
    await tester.pump(BookingScreen.statusPollInterval + BookingScreen.paymentPollInterval);
    await tester.pumpAndSettle();

    expect(find.text('Suivi du trajet & Code de départ'), findsOneWidget);
    expect(find.byType(DepartureCodeCard), findsOneWidget);
    expect(find.text('Koffi arrive dans 3 min'), findsOneWidget);
    final code = env.backend.bookings[_bookingId(env)]!['code_depart'] as String;
    expect(find.textContaining(code, findRichText: true), findsOneWidget);

    // Paiement Flooz depuis l'app.
    await scrollAndTap(tester, find.text('Payer 300 FCFA avec Flooz'));
    await tester.enterText(find.byType(TextFormField).last, '96 12 34 56');
    await tester.tap(find.text('Envoyer la demande de paiement'));
    // Pas de pumpAndSettle ici : l'indicateur « en cours » tourne en continu, et laisser filer
    // le temps déclencherait le sondage qui confirme le paiement.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Paiement en cours'), findsOneWidget);
    expect(find.textContaining('code secret Flooz'), findsOneWidget);

    // Confirmation de l'opérateur, relue par sondage (une relecture « en attente », puis « réussi »).
    await tester.pump(BookingScreen.paymentPollInterval);
    await tester.pump(BookingScreen.paymentPollInterval);
    await tester.pumpAndSettle();
    expect(find.text('Payé'), findsOneWidget);

    await scrollAndTap(tester, find.text('Partager mon trajet'));
    expect(env.externalActions.shares.single, contains('https://kovoit.tg/t/'));

    await scrollAndTap(tester, find.text('Appeler'));
    expect(env.externalActions.calls.single, startsWith('+228'));
  });

  testWidgets('Espèces puis annulation tardive (CA5)', (tester) async {
    await pumpKovoitApp(tester, env: TestEnv.demoSession());
    await openKoffiTrip(tester);
    await scrollTo(tester, find.text('Paiement au conducteur lors de la prise en charge.'));
    expect(find.text('Paiement au conducteur lors de la prise en charge.'), findsOneWidget);
    await scrollAndTap(tester, find.text('Réserver ma place'));

    await scrollAndTap(tester, find.widgetWithText(OutlinedButton, 'Annuler'));
    expect(find.textContaining('comptera comme tardive'), findsOneWidget, reason: '07:20 > 07:00, limite gratuite');
    await tester.tap(find.text('Annuler la réservation'));
    await tester.pumpAndSettle();

    expect(find.text('Réservation annulée'), findsOneWidget);
    expect(find.text('Annulation tardive.'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Annuler'), findsNothing);
    expect(find.text('Rechercher un autre trajet'), findsOneWidget);
  });

  testWidgets('Refus du conducteur (CA4)', (tester) async {
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
    expect(find.text('Adidogomé → Université de Lomé'), findsOneWidget);
    expect(find.text('En attente'), findsOneWidget);
    expect(find.text('Espèces · À régler au conducteur'), findsOneWidget);
  });

  testWidgets('Mes trajets vide : invitation à rechercher', (tester) async {
    await pumpKovoitApp(tester, env: TestEnv.demoSession());
    await tester.tap(find.text('Mes trajets'));
    await tester.pumpAndSettle();

    expect(find.text('Aucune réservation pour l’instant'), findsOneWidget);
  });
}
