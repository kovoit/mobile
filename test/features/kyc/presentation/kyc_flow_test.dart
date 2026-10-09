import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kovoit/features/kyc/data/services/document_capture_service.dart';

import '../../../helpers/test_app.dart';

Future<void> _tap(WidgetTester tester, Finder finder) => scrollAndTap(tester, finder);

Future<void> _openProfile(WidgetTester tester) async {
  await tester.tap(find.text('Profil').last);
  await tester.pumpAndSettle();
}

/// Badge orange de la barre du bas (onglet Profil).
bool _profileBadgeVisible(WidgetTester tester) {
  final badge = tester.widget<Badge>(find.descendant(of: find.byType(NavigationBar), matching: find.byType(Badge)));
  return badge.isLabelVisible;
}

void main() {
  setUpAll(() => initializeDateFormatting('fr'));

  testWidgets('Nouvel inscrit : accès restreint, macaron orange, KYC depuis le Profil', (tester) async {
    final env = await pumpKovoitApp(tester, env: TestEnv.newUserSession());

    // Tableau de bord accessible, réservation restreinte.
    expect(find.text('Le même chemin, à plusieurs. Et moins cher.'), findsOneWidget);
    expect(find.text('Vérifiez votre identité'), findsOneWidget);
    expect(_profileBadgeVisible(tester), isTrue);

    await _openProfile(tester);
    expect(find.text('Sans cette étape, vous ne pouvez ni réserver ni proposer de trajet.'), findsOneWidget);

    await _tap(tester, find.text('Vérification d’identité'));
    expect(find.text('Étape 1 sur 4'), findsOneWidget);

    // Photo de profil, recto, verso : choix appareil photo / galerie.
    for (final piece in ['Photo de profil', 'Pièce d’identité avant', 'Pièce d’identité arrière']) {
      await _tap(tester, find.text('Ajouter : $piece'));
      await _tap(tester, find.text('Prendre une photo'));
    }
    // Selfie : caméra frontale directement, sans galerie.
    await _tap(tester, find.text('Capturer le selfie'));
    expect(env.camera.requests.last, CaptureSource.frontCamera);
    expect(find.text('Envoyer mon dossier'), findsOneWidget, reason: 'les 4 pièces sont fournies');
    expect(env.camera.discarded, hasLength(4), reason: 'aucune pièce ne reste sur l’appareil');

    await _tap(tester, find.text('Envoyer mon dossier'));
    expect(find.text('Dossier envoyé'), findsOneWidget);

    await _tap(tester, find.text('Continuer'));
    expect(find.text('En attente'), findsOneWidget);
    expect(_profileBadgeVisible(tester), isFalse, reason: 'plus d’action attendue de l’utilisateur');

    await tester.tap(find.text('Rechercher'));
    await tester.pumpAndSettle();
    expect(find.text('Vérification en cours'), findsOneWidget);
  });

  testWidgets('Dossier refusé : motif affiché, macaron de retour', (tester) async {
    // Décision de l'administrateur prise avant l'ouverture de l'application.
    final env = TestEnv.newUserSession();
    final userId = int.parse(env.storage.access!.replaceFirst('mock-access-', ''));
    env.backend.kycDossier(userId, 'passager')
      ..pieces.addAll(['photo_profil', 'identite_recto', 'identite_verso', 'selfie'])
      ..statut = 'en_attente';
    await env.backend.simulateAdminDecision(approve: false);
    await pumpKovoitApp(tester, env: env);

    await _openProfile(tester);
    expect(find.text('Refusé'), findsOneWidget);
    expect(_profileBadgeVisible(tester), isTrue);

    await _tap(tester, find.text('Vérification d’identité'));
    expect(find.text('Dossier refusé'), findsOneWidget);
    expect(find.textContaining('Photo de la pièce illisible'), findsOneWidget);
    expect(find.text('Ajouter : Photo de profil'), findsOneWidget, reason: 'les pièces sont à renvoyer');
  });

  testWidgets('Mode conducteur refusé sans droits → check-list « Devenir conducteur »', (tester) async {
    await pumpKovoitApp(tester, env: TestEnv.demoSession());
    await _openProfile(tester);

    await _tap(tester, find.text('Passer en mode conducteur'));

    expect(find.text('Devenir conducteur'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.ancestor(of: find.text('Passer en mode conducteur'), matching: find.byType(FilledButton)),
    );
    expect(button.onPressed, isNull, reason: 'KYC conducteur et véhicule manquants');
  });

  testWidgets('Conducteur complet : véhicule déclaré puis bascule vers l’Espace Conducteur et retour', (tester) async {
    final env = TestEnv.demoSession();
    env.backend.kycDossier(1, 'conducteur')
      ..pieces.addAll(['permis', 'carte_grise_ou_assurance', 'photo_vehicule'])
      ..statut = 'verifie';
    await pumpKovoitApp(tester, env: env);
    await _openProfile(tester);

    await _tap(tester, find.text('Mon véhicule'));
    await tester.enterText(find.widgetWithText(TextFormField, 'Toyota'), 'Toyota');
    await tester.enterText(find.widgetWithText(TextFormField, 'Yaris'), 'Yaris');
    await tester.enterText(find.widgetWithText(TextFormField, 'Gris'), 'Gris');
    await tester.enterText(find.widgetWithText(TextFormField, 'TG 4827 AU'), 'tg 4827 au');
    await _tap(tester, find.text('Enregistrer mon véhicule'));

    expect(find.text('Toyota Yaris · TG 4827 AU'), findsOneWidget);
    expect(find.text('Déclaré'), findsOneWidget);

    await _tap(tester, find.text('Passer en mode conducteur'));
    expect(find.text('Espace Conducteur'), findsOneWidget);
    expect(find.text('Publier'), findsOneWidget);

    await _openProfile(tester);
    await _tap(tester, find.text('Passer en mode passager'));
    expect(find.text('Le même chemin, à plusieurs. Et moins cher.'), findsOneWidget);
  });
}
