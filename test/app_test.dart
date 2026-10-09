import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'helpers/test_app.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr'));

  testWidgets('Sans session : Splash puis écran de connexion', (tester) async {
    await pumpKovoitApp(tester);

    expect(find.text('Connectez-vous pour commencer votre trajet'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
  });

  testWidgets('Session existante : arrivée directe sur l’accueil passager', (tester) async {
    await pumpKovoitApp(tester, env: TestEnv.demoSession());

    expect(find.text('Rechercher un trajet'), findsOneWidget);
    expect(find.text('Mes trajets'), findsOneWidget);
  });

  testWidgets('La barre du bas change d’onglet', (tester) async {
    await pumpKovoitApp(tester, env: TestEnv.demoSession());

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    expect(find.text('Kodjo Mensah'), findsOneWidget);
    expect(find.text('Téléphone vérifié'), findsOneWidget);
  });
}
