import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env.dart';
import '../../../../core/mock/fake_backend.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/storage/token_storage.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/datasources/fake_auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';

/// Source de données : fausse API en mémoire en mode démo (Env.useMockApi), sinon le backend.
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  if (Env.useMockApi) return FakeAuthRemoteDataSource(ref.watch(fakeBackendProvider));
  return ApiAuthRemoteDataSource(ref.watch(apiServiceProvider));
});

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    remote: ref.watch(authRemoteDataSourceProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  ),
);

/// Durée minimale d'affichage du Splash (surchargée à zéro dans les tests).
final splashMinDurationProvider = Provider<Duration>((ref) => const Duration(milliseconds: 1200));
