import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kovoit/app.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr'));

  testWidgets('Splash puis arrivée sur l’onglet Rechercher', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: KovoitApp()));

    expect(find.text('Même trajet, moins cher'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Rechercher un trajet'), findsOneWidget);
    expect(find.text('Mes trajets'), findsOneWidget); // onglet de la barre du bas
    expect(find.text('Profil'), findsOneWidget);
  });

  testWidgets('La barre du bas change d’onglet', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: KovoitApp()));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    expect(find.text('Votre compte et votre vérification.'), findsOneWidget);
  });
}
