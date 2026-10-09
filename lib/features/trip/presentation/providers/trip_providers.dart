import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env.dart';
import '../../../../core/mock/fake_backend.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/trip_remote_data_source.dart';
import '../../data/repositories/trip_repository_impl.dart';
import '../../domain/entities/trip.dart';
import '../../domain/repositories/trip_repository.dart';

final tripRemoteDataSourceProvider = Provider<TripRemoteDataSource>((ref) {
  if (Env.useMockApi) return FakeTripRemoteDataSource(ref.watch(fakeBackendProvider));
  return DioTripRemoteDataSource(ref.watch(dioProvider));
});

final tripRepositoryProvider = Provider<TripRepository>((ref) => TripRepositoryImpl(ref.watch(tripRemoteDataSourceProvider)));

/// Détail d'un trajet pour un nombre de places donné : `(id, places)`.
final tripDetailProvider = FutureProvider.autoDispose.family<Trip, (int, int)>(
  (ref, key) => ref.watch(tripRepositoryProvider).fetchTrip(key.$1, places: key.$2),
);
