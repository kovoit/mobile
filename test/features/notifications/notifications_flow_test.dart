import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../helpers/flows.dart';
import '../../helpers/test_app.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr'));

  testWidgets('Notifications : la réservation acceptée apparaît, la toucher ouvre la réservation', (tester) async {
    final env = await pumpKovoitApp(tester, env: TestEnv.demoSession());
    await openKoffiTrip(tester);
    await scrollAndTap(tester, find.text('Réserver ma place'));
    await env.bookings.simulateDriverAccepts(env.backend.bookings.keys.last);
    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profil').last);
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('1 notification non lue'));
    expect(find.text('1 notification non lue'), findsOneWidget);
    await scrollAndTap(tester, find.text('Notifications'));

    expect(find.text('Réservation acceptée'), findsOneWidget);
    expect(find.text('Tout marquer comme lu'), findsOneWidget);
    await tester.tap(find.text('Réservation acceptée'));
    await tester.pumpAndSettle();

    expect(find.text('Suivi du trajet & Code de départ'), findsOneWidget);
    expect(env.backend.notifications.single['lue_le'], isNotNull);
  });

  testWidgets('Notifications : aucune pour l’instant', (tester) async {
    await pumpKovoitApp(tester, env: TestEnv.demoSession());
    await tester.tap(find.text('Profil').last);
    await tester.pumpAndSettle();
    await scrollAndTap(tester, find.text('Notifications'));

    expect(find.text('Aucune notification'), findsOneWidget);
    expect(find.text('Tout marquer comme lu'), findsNothing);
  });
}
