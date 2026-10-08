import 'package:flutter_test/flutter_test.dart';
import 'package:kovoit/core/network/api_exception.dart';
import 'package:kovoit/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:kovoit/features/auth/data/dto/auth_response_dto.dart';
import 'package:kovoit/features/auth/data/dto/user_dto.dart';
import 'package:kovoit/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:kovoit/features/auth/data/services/google_auth_service.dart';
import 'package:kovoit/features/auth/domain/entities/app_user.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_app.dart';

class _MockRemote extends Mock implements AuthRemoteDataSource {}

class _MockGoogle extends Mock implements GoogleAuthService {}

const _userDto = UserDto(
  id: 7,
  prenom: 'Afi',
  nom: 'Amégan',
  email: 'afi@exemple.com',
  telephone: '+22891234567',
  telephoneVerifie: true,
  kycPassager: 'en_attente',
);

void main() {
  late _MockRemote remote;
  late _MockGoogle google;
  late InMemoryTokenStorage storage;
  late AuthRepositoryImpl repository;

  setUp(() {
    remote = _MockRemote();
    google = _MockGoogle();
    storage = InMemoryTokenStorage();
    repository = AuthRepositoryImpl(remote: remote, tokenStorage: storage, google: google);
    when(() => google.signOut()).thenAnswer((_) async {});
  });

  test('login normalise l’e-mail, stocke les jetons et mappe l’utilisateur', () async {
    when(() => remote.login(email: 'afi@exemple.com', password: 'secret123'))
        .thenAnswer((_) async => const AuthResponseDto(access: 'a', refresh: 'r', user: _userDto));

    final user = await repository.login(email: '  AFI@exemple.com ', password: 'secret123');

    expect(storage.access, 'a');
    expect(storage.refresh, 'r');
    expect(user.nomComplet, 'Afi Amégan');
    expect(user.kycPassager, KycStatus.enAttente);
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

  test('Google annulé : aucun appel au backend', () async {
    when(() => google.getIdToken()).thenAnswer((_) async => null);

    expect(await repository.signInWithGoogle(), isNull);
    verifyNever(() => remote.loginWithGoogle(any()));
  });

  test('Google : l’ID token est échangé contre une session', () async {
    when(() => google.getIdToken()).thenAnswer((_) async => 'id-token');
    when(() => remote.loginWithGoogle('id-token'))
        .thenAnswer((_) async => const AuthResponseDto(access: 'a', refresh: 'r', user: _userDto));

    final user = await repository.signInWithGoogle();

    expect(user?.email, 'afi@exemple.com');
    expect(storage.access, 'a');
  });

  test('logout efface la session locale même si l’API échoue', () async {
    storage.access = 'a';
    storage.refresh = 'r';
    when(() => remote.logout('r')).thenThrow(const NetworkApiException());

    await repository.logout();

    expect(storage.access, isNull);
    expect(storage.refresh, isNull);
    verify(() => google.signOut()).called(1);
  });
}
