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
  late AuthRepositoryImpl repository;

  setUp(() {
    remote = _MockRemote();
    storage = InMemoryTokenStorage();
    repository = AuthRepositoryImpl(remote: remote, tokenStorage: storage);
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
}
