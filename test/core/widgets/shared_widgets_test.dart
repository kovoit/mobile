import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kovoit/core/theme/app_theme.dart';
import 'package:kovoit/core/widgets/widgets.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)),
    );

void main() {
  group('OtpCodeInput', () {
    testWidgets('appelle onCompleted quand les 6 chiffres sont saisis', (tester) async {
      String? completed;
      await tester.pumpWidget(_wrap(OtpCodeInput(onCompleted: (c) => completed = c)));

      await tester.enterText(find.byType(TextField), '731906');
      await tester.pump();

      expect(completed, '731906');
      for (final digit in ['7', '3', '1', '9', '0', '6']) {
        expect(find.text(digit), findsOneWidget);
      }
    });

    testWidgets('ignore les caractères non numériques et limite la longueur', (tester) async {
      String? last;
      await tester.pumpWidget(_wrap(OtpCodeInput(length: 4, onChanged: (c) => last = c)));

      await tester.enterText(find.byType(TextField), '48a2167');
      await tester.pump();

      expect(last, '4821');
    });
  });

  group('PlaceStepper', () {
    testWidgets('respecte les bornes min et max', (tester) async {
      var value = 1;
      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (context, setState) => PlaceStepper(
              value: value,
              max: 2,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      );

      await tester.tap(find.byTooltip('Retirer une place'));
      await tester.pump();
      expect(value, 1);

      await tester.tap(find.byTooltip('Ajouter une place'));
      await tester.pump();
      await tester.tap(find.byTooltip('Ajouter une place'));
      await tester.pump();
      expect(value, 2);
    });
  });

  testWidgets('SegmentedToggle renvoie la valeur touchée', (tester) async {
    var selected = 'voiture';
    await tester.pumpWidget(
      _wrap(
        StatefulBuilder(
          builder: (context, setState) => SegmentedToggle<String>(
            selected: selected,
            onChanged: (v) => setState(() => selected = v),
            options: const [
              SegmentedOption(value: 'moto', label: 'Moto'),
              SegmentedOption(value: 'voiture', label: 'Voiture'),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Moto'));
    await tester.pump();
    expect(selected, 'moto');
  });

  testWidgets('PrimaryButton en chargement est désactivé', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_wrap(PrimaryButton(label: 'Réserver ma place', isLoading: true, onPressed: () => taps++)));

    expect(find.text('Réserver ma place'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(FilledButton));
    expect(taps, 0);
  });

  testWidgets('DriverCard affiche les valeurs fournies sans les recalculer', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const SingleChildScrollView(
          child: DriverCard(
            driverName: 'Kodjo Mensah',
            rating: 4.9,
            isVerified: true,
            vehicleLabel: 'Toyota Yaris',
            placesLabel: '2 places restantes',
            departureLabel: 'Départ 07:30 · 1.2 km de vous',
            routeLabel: 'Adidogomé → Université de Lomé',
            price: 300,
          ),
        ),
      ),
    );

    expect(find.text('Kodjo Mensah'), findsOneWidget);
    expect(find.text('Identité vérifiée'), findsOneWidget);
    expect(find.text('300 FCFA'), findsOneWidget);
    expect(find.text('4.9'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    expect(find.text('KM'), findsOneWidget); // initiales (pas de photo)
  });

  testWidgets('KovoitTextField mot de passe bascule la visibilité', (tester) async {
    await tester.pumpWidget(_wrap(const KovoitTextField(label: 'Mot de passe', isPassword: true)));

    EditableText editable() => tester.widget<EditableText>(find.byType(EditableText));
    expect(editable().obscureText, isTrue);

    await tester.tap(find.byTooltip('Afficher le mot de passe'));
    await tester.pump();
    expect(editable().obscureText, isFalse);
  });
}
