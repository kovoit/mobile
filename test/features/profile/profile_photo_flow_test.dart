import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kovoit/core/config/env.dart';
import 'package:kovoit/core/services/photo_capture_service.dart';
import 'package:kovoit/core/widgets/user_avatar.dart';
import 'package:kovoit/features/profile/presentation/widgets/profile_photo_picker.dart';

import '../../helpers/test_app.dart';

/// Appareil photo simulé qui renvoie un fichier qui n'est pas une image (refusé par le backend).
class _PdfCamera extends FakeCaptureService {
  @override
  Future<String?> capture(CaptureSource source) async {
    requests.add(source);
    return 'test/releve.pdf';
  }
}

class _PdfEnv extends TestEnv {
  _PdfEnv() : super(accessToken: 'mock-access-1');

  final _PdfCamera _pdfCamera = _PdfCamera();

  @override
  FakeCaptureService get camera => _pdfCamera;
}

Future<void> _choosePhoto(WidgetTester tester, String option) async {
  await tester.tap(find.text('Profil').last);
  await tester.pumpAndSettle();
  await tester.tap(find.byType(ProfilePhotoPicker));
  await tester.pumpAndSettle();
  expect(find.text('Prendre une photo'), findsOneWidget);
  expect(find.text('Choisir dans la galerie'), findsOneWidget);
  await tester.tap(find.text(option));
  await tester.pumpAndSettle();
}

String? _avatarUrl(WidgetTester tester) => tester
    .widget<UserAvatar>(find.descendant(of: find.byType(ProfilePhotoPicker), matching: find.byType(UserAvatar)))
    .photoUrl;

void main() {
  setUpAll(() => initializeDateFormatting('fr'));

  testWidgets('CA-003-3 (mobile) : photo choisie dans la galerie → avatar mis à jour, fichier supprimé', (
    tester,
  ) async {
    final env = await pumpKovoitApp(tester, env: TestEnv.demoSession());
    expect(env.backend.userJson(1)['photo'], isNull);

    await _choosePhoto(tester, 'Choisir dans la galerie');

    expect(env.camera.requests, [CaptureSource.gallery]);
    expect(find.text('Photo enregistrée.'), findsOneWidget);
    final path = env.backend.userJson(1)['photo'] as String;
    expect(path, startsWith('/media/photos_profil/'), reason: 'chemin relatif, comme le vrai backend');
    // Décision Q1 révisée : le chemin est complété avec l'origine de l'API avant d'arriver à l'avatar.
    expect(_avatarUrl(tester), '${Uri.parse(Env.apiBaseUrl).origin}$path');
    // URL simulée injoignable : l'avatar garde les initiales, sans erreur affichée.
    expect(find.descendant(of: find.byType(ProfilePhotoPicker), matching: find.text('KM')), findsOneWidget);
    expect(env.camera.discarded, ['test/fake_piece_1.jpg'], reason: 'aucune copie gardée après envoi');
  });

  testWidgets('« Prendre une photo » ouvre la caméra frontale', (tester) async {
    final env = await pumpKovoitApp(tester, env: TestEnv.demoSession());

    await _choosePhoto(tester, 'Prendre une photo');

    expect(env.camera.requests, [CaptureSource.frontCamera]);
    expect(find.text('Photo enregistrée.'), findsOneWidget);
    expect(env.camera.discarded, hasLength(1));
  });

  testWidgets('image refusée (400 erreurs.photo) : message affiché, avatar inchangé, fichier supprimé', (tester) async {
    final env = await pumpKovoitApp(tester, env: _PdfEnv());

    await _choosePhoto(tester, 'Choisir dans la galerie');

    expect(find.textContaining('Transférez une image valide'), findsOneWidget);
    expect(find.text('Photo enregistrée.'), findsNothing);
    expect(_avatarUrl(tester), isNull);
    expect(env.backend.userJson(1)['photo'], isNull);
    expect(env.camera.discarded, ['test/releve.pdf']);
  });

  testWidgets('annulation du choix : aucun envoi', (tester) async {
    final env = await pumpKovoitApp(tester, env: TestEnv.demoSession());
    await tester.tap(find.text('Profil').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ProfilePhotoPicker));
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(10, 10)); // ferme la feuille sans choisir
    await tester.pumpAndSettle();

    expect(env.camera.requests, isEmpty);
    expect(env.backend.userJson(1)['photo'], isNull);
  });
}
