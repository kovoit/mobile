import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env.dart';
import '../../../../core/mock/fake_wallet.dart';
import '../../../../core/network/api_service.dart';
import '../../data/datasources/trip_remote_data_source.dart';
import '../../data/repositories/trip_repository_impl.dart';
import '../../domain/entities/trip.dart';
import '../../domain/repositories/trip_repository.dart';

final tripRemoteDataSourceProvider = Provider<TripRemoteDataSource>((ref) {
  if (Env.useMockApi) return FakeTripRemoteDataSource(ref.watch(fakeWalletProvider));
  return ApiTripRemoteDataSource(ref.watch(apiServiceProvider));
});

final tripRepositoryProvider = Provider<TripRepository>((ref) => TripRepositoryImpl(ref.watch(tripRemoteDataSourceProvider)));

/// Détail d'un trajet (avec l'aperçu du paiement du passager connecté).
final tripDetailProvider = FutureProvider.autoDispose.family<Trip, String>(
  (ref, id) => ref.watch(tripRepositoryProvider).fetchTrip(id),
);
