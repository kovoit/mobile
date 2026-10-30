import 'package:flutter_test/flutter_test.dart';
import 'package:kovoit/core/network/api_exception.dart';
import 'package:kovoit/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:kovoit/features/auth/data/dto/code_envoye_dto.dart';
import 'package:kovoit/features/auth/data/dto/connexion_dto.dart';
import 'package:kovoit/features/auth/data/dto/profil_dto.dart';
import 'package:kovoit/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:kovoit/features/auth/domain/entities/app_user.dart';
import 'package:kovoit/features/auth/domain/entities/registration.dart';
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

  group('inscription et vérification de l’e-mail (F-070, F-071)', () {
    const registration = Registration(
      prenom: ' Afi ',
      nom: ' Amégan ',
      email: '  AFI@exemple.com ',
      telephone: '+22891234567',
      motDePasse: ' Secret du 30/10 ',
      cguAcceptees: true,
    );

    void stubRegister() => when(
          () => remote.register(
            prenom: any(named: 'prenom'),
            nom: any(named: 'nom'),
            email: any(named: 'email'),
            telephone: any(named: 'telephone'),
            motDePasse: any(named: 'motDePasse'),
            cguAcceptees: any(named: 'cguAcceptees'),
          ),
        ).thenAnswer((_) async => const CodeEnvoyeDto(email: 'afi@exemple.com', delaiRenvoiS: 45));

    test('register : e-mail normalisé, noms nettoyés, mot de passe tel quel, délai du serveur, aucun jeton', () async {
      stubRegister();

      final challenge = await repository.register(registration);

      verify(
        () => remote.register(
          prenom: 'Afi',
          nom: 'Amégan',
          email: 'afi@exemple.com',
          telephone: '+22891234567',
          motDePasse: ' Secret du 30/10 ',
          cguAcceptees: true,
        ),
      ).called(1);
      expect(challenge.email, 'afi@exemple.com');
      expect(challenge.resendIn, const Duration(seconds: 45));
      expect(storage.access, isNull);
      expect(storage.refresh, isNull);
    });

    test('register : 409 EMAIL_DEJA_UTILISE propagé, aucun jeton', () async {
      when(
        () => remote.register(
          prenom: any(named: 'prenom'),
          nom: any(named: 'nom'),
          email: any(named: 'email'),
          telephone: any(named: 'telephone'),
          motDePasse: any(named: 'motDePasse'),
          cguAcceptees: any(named: 'cguAcceptees'),
        ),
      ).thenThrow(const ConflictApiException('Déjà utilisé.', code: 'EMAIL_DEJA_UTILISE'));

      await expectLater(
        repository.register(registration),
        throwsA(isA<ConflictApiException>().having((e) => e.code, 'code', 'EMAIL_DEJA_UTILISE')),
      );
      expect(storage.access, isNull);
    });

    test('le mot de passe n’apparaît pas dans toString()', () {
      expect(registration.toString(), isNot(contains('Secret')));
    });

    test('verifyEmail stocke les jetons et mappe l’utilisateur', () async {
      when(() => remote.verifyEmail(email: 'afi@exemple.com', code: '123456')).thenAnswer(
        (_) async => const ConnexionDto(utilisateur: _profil, access: 'a', refresh: 'r', nouveauCompte: true),
      );

      final user = await repository.verifyEmail(email: ' Afi@exemple.com', code: '123456');

      expect(storage.access, 'a');
      expect(storage.refresh, 'r');
      expect(user.id, 'b5a1-uuid');
      expect(user.nomComplet, 'Afi Amégan');
      expect(user.kycPassager, KycStatus.enAttente);
      expect(user.profilComplet, isTrue);
    });

    test('verifyEmail : CODE_OTP_INVALIDE propagé, aucun jeton', () async {
      when(() => remote.verifyEmail(email: any(named: 'email'), code: any(named: 'code')))
          .thenThrow(const BadRequestApiException('Code invalide ou expiré.', code: 'CODE_OTP_INVALIDE'));

      await expectLater(
        repository.verifyEmail(email: 'afi@exemple.com', code: '000000'),
        throwsA(isA<BadRequestApiException>().having((e) => e.code, 'code', 'CODE_OTP_INVALIDE')),
      );
      expect(storage.access, isNull);
    });

    test('resendVerificationCode normalise l’e-mail et renvoie delai_renvoi_s', () async {
      when(() => remote.resendVerificationCode('afi@exemple.com'))
          .thenAnswer((_) async => const CodeEnvoyeDto(email: 'afi@exemple.com', delaiRenvoiS: 60));

      final challenge = await repository.resendVerificationCode(' AFI@exemple.com');

      expect(challenge.email, 'afi@exemple.com');
      expect(challenge.resendIn, const Duration(seconds: 60));
    });
  });

  group('connexion (F-072)', () {
    test('login : e-mail normalisé, mot de passe tel quel, jetons stockés (jamais le mot de passe)', () async {
      when(() => remote.login(email: 'afi@exemple.com', motDePasse: ' Mot de passe ')).thenAnswer(
        (_) async => const ConnexionDto(utilisateur: _profil, access: 'a', refresh: 'r'),
      );

      final user = await repository.login(email: ' AFI@exemple.com ', password: ' Mot de passe ');

      expect(user.email, 'afi@exemple.com');
      expect(storage.access, 'a');
      expect(storage.refresh, 'r');
    });

    for (final (label, error) in [
      ('401 IDENTIFIANTS_INVALIDES', const UnauthorizedApiException('Email ou mot de passe incorrect.', code: 'IDENTIFIANTS_INVALIDES')),
      ('403 EMAIL_NON_VERIFIE', const ForbiddenApiException('Adresse non vérifiée.', code: 'EMAIL_NON_VERIFIE')),
      ('429 TROP_DE_REQUETES', const TooManyAttemptsApiException('Trop de tentatives.', code: 'TROP_DE_REQUETES')),
    ]) {
      test('login : $label propagé, aucun jeton', () async {
        when(() => remote.login(email: any(named: 'email'), motDePasse: any(named: 'motDePasse'))).thenThrow(error);

        await expectLater(
          repository.login(email: 'afi@exemple.com', password: 'mauvais'),
          throwsA(isA<ApiException>().having((e) => e.code, 'code', error.code)),
        );
        expect(storage.access, isNull);
        expect(storage.refresh, isNull);
      });
    }
  });

  group('mot de passe oublié (F-073)', () {
    test('requestPasswordReset normalise l’e-mail et renvoie le délai', () async {
      when(() => remote.requestPasswordReset('afi@exemple.com'))
          .thenAnswer((_) async => const CodeEnvoyeDto(email: 'afi@exemple.com', delaiRenvoiS: 60));

      final challenge = await repository.requestPasswordReset('Afi@Exemple.com ');

      expect(challenge.email, 'afi@exemple.com');
      expect(challenge.resendIn, const Duration(seconds: 60));
    });

    test('resetPassword : e-mail normalisé, code et mot de passe envoyés, aucun jeton stocké', () async {
      when(
        () => remote.resetPassword(email: 'afi@exemple.com', code: '123456', motDePasse: 'Nouveau-2026'),
      ).thenAnswer((_) async {});

      await repository.resetPassword(email: ' AFI@exemple.com', code: '123456', password: 'Nouveau-2026');

      verify(
        () => remote.resetPassword(email: 'afi@exemple.com', code: '123456', motDePasse: 'Nouveau-2026'),
      ).called(1);
      expect(storage.access, isNull);
      expect(storage.refresh, isNull);
    });
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
