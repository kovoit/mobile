import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../helpers/flows.dart';
import '../../helpers/test_app.dart';

Future<void> _openDeleteScreen(WidgetTester tester) async {
  await tester.tap(find.text('Profil').last);
  await tester.pumpAndSettle();
  await scrollAndTap(tester, find.text('Supprimer mon compte'));
  expect(find.text('Cette action est définitive.'), findsOneWidget);
}

void main() {
  setUpAll(() => initializeDateFormatting('fr'));

  testWidgets('Supprimer mon compte : confirmation SUPPRIMER, puis retour à la connexion', (tester) async {
    final env = await pumpKovoitApp(tester, env: TestEnv.demoSession());
    await _openDeleteScreen(tester);

    final bouton = find.widgetWithText(FilledButton, 'Supprimer définitivement mon compte');
    await scrollTo(tester, bouton);
    expect(tester.widget<FilledButton>(bouton).onPressed, isNull, reason: 'confirmation obligatoire');
    await tester.enterText(find.byType(TextField), 'supprimer');
    await tester.pump();
    await scrollAndTap(tester, bouton);

    expect(find.text('Connectez-vous pour commencer votre trajet'), findsOneWidget);
    expect(env.storage.access, isNull);
  });

  testWidgets('Supprimer mon compte : refus expliqué s’il reste une réservation en cours', (tester) async {
    await pumpKovoitApp(tester, env: TestEnv.demoSession());
    await openKoffiTrip(tester);
    await scrollAndTap(tester, find.text('Réserver ma place'));
    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pumpAndSettle();
    await _openDeleteScreen(tester);

    await scrollTo(tester, find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'SUPPRIMER');
    await tester.pump();
    await scrollAndTap(tester, find.widgetWithText(FilledButton, 'Supprimer définitivement mon compte'));

    expect(find.text('Suppression impossible pour le moment'), findsOneWidget);
    expect(find.textContaining('réservation en cours'), findsOneWidget);
  });
}
