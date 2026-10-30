import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env.dart';
import '../../../../core/mock/fake_backend.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/services/photo_capture_service.dart';
import '../../../auth/presentation/providers/session_controller.dart';
import '../../data/datasources/kyc_remote_data_source.dart';
import '../../data/repositories/kyc_repository_impl.dart';
import '../../domain/entities/kyc_dossier.dart';
import '../../domain/repositories/kyc_repository.dart';

final kycRemoteDataSourceProvider = Provider<KycRemoteDataSource>((ref) {
  if (Env.useMockApi) return FakeKycRemoteDataSource(ref.watch(fakeBackendProvider));
  return ApiKycRemoteDataSource(ref.watch(apiServiceProvider));
});

final kycRepositoryProvider = Provider<KycRepository>(
  (ref) => KycRepositoryImpl(ref.watch(kycRemoteDataSourceProvider), ref.watch(photoCaptureServiceProvider)),
);

/// Dossiers KYC de l'utilisateur connecté (passager et conducteur).
class KycController extends AsyncNotifier<Map<KycType, KycDossier>> {
  KycRepository get _repository => ref.read(kycRepositoryProvider);

  @override
  Future<Map<KycType, KycDossier>> build() {
    // Nouveau compte connecté → nouveaux dossiers.
    ref.watch(sessionControllerProvider.select((s) => s.value?.id));
    return _repository.fetchDossiers();
  }

  void _put(KycDossier dossier) => state = AsyncData({...?state.value, dossier.type: dossier});

  Future<void> uploadPiece(KycType type, KycPieceType piece, String filePath) async {
    _put(await _repository.uploadPiece(type: type, piece: piece, filePath: filePath));
  }

  /// Envoie le dossier puis relit l'utilisateur : son statut KYC passe « en attente ».
  Future<void> submit(KycType type) async {
    _put(await _repository.submit(type));
    await ref.read(sessionControllerProvider.notifier).refreshUser();
  }
}

final kycControllerProvider = AsyncNotifierProvider<KycController, Map<KycType, KycDossier>>(KycController.new);
