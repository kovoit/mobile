import 'package:flutter_test/flutter_test.dart';
import 'package:kovoit/core/network/api_exception.dart';
import 'package:kovoit/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:kovoit/features/auth/data/dto/connexion_dto.dart';
import 'package:kovoit/features/auth/data/dto/profil_dto.dart';
import 'package:kovoit/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:kovoit/features/auth/domain/entities/app_user.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_app.dart';

class _MockRemote extends Mock implements AuthRemoteDataSource {}

const _profil = ProfilDto(
  id: 'b5a1-uuid',
  email: 'afi@exemple.com',
  prenom: 'Afi',
  nom: 'Amégan',
  telephone: '+22891234567',
  profilComplet: true,
  kyc: {'passager': 'en_attente', 'conducteur': 'non_verifie'},
);

void main() {
  late _MockRemote remote;
  late InMemoryTokenStorage storage;
  late FakeCaptureService capture;
  late AuthRepositoryImpl repository;

  setUp(() {
    remote = _MockRemote();
    storage = InMemoryTokenStorage();
    capture = FakeCaptureService();
    repository = AuthRepositoryImpl(remote: remote, tokenStorage: storage, capture: capture);
  });

  test('requestCode normalise l’e-mail et renvoie le délai de renvoi', () async {
    when(() => remote.requestCode('afi@exemple.com')).thenAnswer((_) async {});

    final challenge = await repository.requestCode('  AFI@exemple.com ');

    expect(challenge.email, 'afi@exemple.com');
    expect(challenge.resendIn, AuthRepositoryImpl.resendDelay);
  });

  test('verifyCode stocke les jetons et mappe l’utilisateur', () async {
    when(() => remote.verifyCode(email: 'afi@exemple.com', code: '123456')).thenAnswer(
      (_) async => const ConnexionDto(utilisateur: _profil, access: 'a', refresh: 'r'),
    );

    final user = await repository.verifyCode(email: ' Afi@exemple.com', code: '123456');

    expect(storage.access, 'a');
    expect(storage.refresh, 'r');
    expect(user.id, 'b5a1-uuid');
    expect(user.nomComplet, 'Afi Amégan');
    expect(user.kycPassager, KycStatus.enAttente);
    expect(user.profilComplet, isTrue);
  });

  test('restoreSession sans jeton ne fait aucun appel', () async {
    expect(await repository.restoreSession(), isNull);
    verifyNever(() => remote.me());
  });

  test('restoreSession efface les jetons si la session est expirée', () async {
    storage.access = 'expired';
    storage.refresh = 'expired';
    when(() => remote.me()).thenThrow(const UnauthorizedApiException('expirée'));

    expect(await repository.restoreSession(), isNull);
    expect(storage.access, isNull);
  });

  test('restoreSession propage une erreur réseau (le Splash propose de réessayer)', () async {
    storage.access = 'valid';
    when(() => remote.me()).thenThrow(const NetworkApiException());

    expect(repository.restoreSession(), throwsA(isA<NetworkApiException>()));
  });

  test('logout efface la session locale même si l’API échoue', () async {
    storage.access = 'a';
    storage.refresh = 'r';
    when(() => remote.logout('r')).thenThrow(const NetworkApiException());

    await repository.logout();

    expect(storage.access, isNull);
    expect(storage.refresh, isNull);
  });

  group('updatePhoto (D-19, contrat C3)', () {
    const url = 'https://api.kovoit.tg/media/photos_profil/afi.jpg';
    const avecPhoto = ProfilDto(
      id: 'b5a1-uuid',
      email: 'afi@exemple.com',
      prenom: 'Afi',
      nom: 'Amégan',
      telephone: '+22891234567',
      photo: url,
      profilComplet: true,
      kyc: {'passager': 'en_attente', 'conducteur': 'non_verifie'},
    );

    test('renvoie le profil avec l’URL absolue de la photo, inchangée, et supprime le fichier', () async {
      when(() => remote.updatePhoto('/cache/photo.jpg')).thenAnswer((_) async => avecPhoto);

      final user = await repository.updatePhoto('/cache/photo.jpg');

      expect(user.photoUrl, url);
      expect(capture.discarded, ['/cache/photo.jpg']);
    });

    test('400 DONNEES_INVALIDES : erreurs.photo remonte, le fichier est quand même supprimé', () async {
      when(() => remote.updatePhoto('/cache/photo.jpg')).thenThrow(
        ApiException.fromResponse(400, {
          'statut': 'failed',
          'message': 'Les données envoyées sont invalides.',
          'reponse': {
            'code': 'DONNEES_INVALIDES',
            'erreurs': {
              'photo': ['Transférez une image valide.'],
            },
          },
        }),
      );

      await expectLater(
        repository.updatePhoto('/cache/photo.jpg'),
        throwsA(
          isA<BadRequestApiException>()
              .having((e) => e.code, 'code', 'DONNEES_INVALIDES')
              .having((e) => e.fieldErrors['photo'], 'erreurs.photo', 'Transférez une image valide.'),
        ),
      );
      expect(capture.discarded, ['/cache/photo.jpg']);
    });

    test('erreur réseau : le fichier est supprimé, l’erreur est propagée', () async {
      when(() => remote.updatePhoto('/cache/photo.jpg')).thenThrow(const NetworkApiException());

      await expectLater(repository.updatePhoto('/cache/photo.jpg'), throwsA(isA<NetworkApiException>()));
      expect(capture.discarded, ['/cache/photo.jpg']);
    });

    test('403 (compte bloqué côté serveur) : le fichier est supprimé, l’erreur est propagée', () async {
      when(() => remote.updatePhoto('/cache/photo.jpg')).thenThrow(const ForbiddenApiException('Refusé.'));

      await expectLater(repository.updatePhoto('/cache/photo.jpg'), throwsA(isA<ForbiddenApiException>()));
      expect(capture.discarded, ['/cache/photo.jpg']);
    });
  });
}
