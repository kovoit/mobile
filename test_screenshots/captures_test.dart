// Captures de l'app pour le site vitrine, rendues depuis le vrai code Flutter (mode démo).
// Hors de la suite normale. Régénérer après un changement d'écran :
//
//   flutter test test_screenshots --update-goldens
//
// puis copier test_screenshots/captures/*.png dans site/src/assets/captures/.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kovoit/app.dart';
import 'package:kovoit/core/router/app_router.dart';
import 'package:kovoit/core/router/routes.dart';
import 'package:kovoit/features/booking/presentation/screens/booking_screen.dart';

import '../test/helpers/flows.dart';
import '../test/helpers/test_app.dart';

/// Écran de téléphone 393 × 852 (format du cadre du site), barre d'état de 44 px.
const _size = Size(393, 852);
const _ratio = 2.0;

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    loader.addFont(File(path).readAsBytes().then((bytes) => ByteData.view(Uint8List.fromList(bytes).buffer)));
  }
  await loader.load();
}

/// Icônes Material livrées avec le SDK Flutter (le testeur ne les charge pas seul).
String _materialIcons() {
  var dir = File(Platform.resolvedExecutable).parent;
  while (!Directory('${dir.path}/material_fonts').existsSync()) {
    dir = dir.parent;
  }
  return '${dir.path}/material_fonts/materialicons-regular.otf';
}

Future<TestEnv> _start(WidgetTester tester, TestEnv env) async {
  tester.view
    ..physicalSize = _size * _ratio
    ..devicePixelRatio = _ratio
    ..padding = const FakeViewPadding(top: 44 * _ratio);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(overrides: env.overrides, child: const KovoitApp()));
  await tester.pumpAndSettle();
  return env;
}

Future<void> _top(WidgetTester tester) async {
  final lists = find.byType(Scrollable);
  if (lists.evaluate().isNotEmpty) {
    await tester.drag(lists.first, const Offset(0, 3000));
    await tester.pumpAndSettle();
  }
}

/// Laisse les images (logo) se décoder en temps réel avant la capture.
Future<void> _capture(WidgetTester tester, String name) async {
  for (final element in find.byType(Image).evaluate()) {
    final image = element.widget as Image;
    await tester.runAsync(() => precacheImage(image.image, element));
  }
  await tester.pumpAndSettle();
  await expectLater(find.byType(KovoitApp), matchesGoldenFile('captures/$name.png'));
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr');
    await _loadFont('PlusJakartaSans', [for (final w in [400, 500, 600, 700, 800]) 'assets/fonts/PlusJakartaSans-$w.ttf']);
    await _loadFont('MaterialIcons', [_materialIcons()]);
  });

  testWidgets('rechercher un trajet', (tester) async {
    await _start(tester, TestEnv.demoSession());
    await choosePlace(tester, 'Carrefour, quartier, repère…', 'franc', 'Carrefour Franciscain');
    await choosePlace(tester, 'Où allez-vous ?', 'univ', 'Université de Lomé · Entrée sud');
    await _top(tester);
    await _capture(tester, 'rechercher-un-trajet');
  });

  testWidgets('détails et réservation', (tester) async {
    await _start(tester, TestEnv.demoSession());
    await openKoffiTrip(tester);
    // Le paiement par le portefeuille, sous le conducteur et le prix.
    await scrollTo(tester, find.text('Payé avec mon portefeuille'));
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
    await tester.pumpAndSettle();
    await _capture(tester, 'details-reservation');
  });

  testWidgets('suivi et code de départ', (tester) async {
    final env = await _start(tester, TestEnv.demoSession());
    await openKoffiTrip(tester);
    await scrollAndTap(tester, find.text('Réserver ma place'));
    await env.bookings.simulateDriverAccepts(env.backend.bookings.keys.last);
    await tester.pump(BookingScreen.statusPollInterval);
    await tester.pumpAndSettle();
    await _top(tester);
    await _capture(tester, 'suivi-du-trajet-code-de-depart');
  });

  testWidgets('espace conducteur', (tester) async {
    await _start(tester, TestEnv.driverSession());
    await choosePlace(tester, 'Carrefour, quartier, repère…', 'franc', 'Carrefour Franciscain');
    await choosePlace(tester, 'Où allez-vous ?', 'univ', 'Université de Lomé · Entrée sud');
    await _top(tester);
    await _capture(tester, 'espace-conducteur');
  });

  testWidgets('portefeuille', (tester) async {
    final env = TestEnv.demoSession();
    await _start(tester, env);
    ProviderScope.containerOf(tester.element(find.byType(KovoitApp))).read(appRouterProvider).push(Routes.wallet);
    await tester.pumpAndSettle();
    await _capture(tester, 'portefeuille');
  });

  testWidgets('profil vérifié', (tester) async {
    await _start(tester, TestEnv.demoSession());
    ProviderScope.containerOf(tester.element(find.byType(KovoitApp)))
        .read(appRouterProvider)
        .push(Routes.kycSubmitted('passager'));
    await tester.pumpAndSettle();
    await _capture(tester, 'profil-verifie');
  });
}
