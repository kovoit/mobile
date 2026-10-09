import '../../domain/entities/kyc_dossier.dart';
import '../../domain/repositories/kyc_repository.dart';
import '../datasources/kyc_remote_data_source.dart';
import '../services/document_capture_service.dart';

class KycRepositoryImpl implements KycRepository {
  KycRepositoryImpl(this._remote, this._capture);

  final KycRemoteDataSource _remote;
  final DocumentCaptureService _capture;

  @override
  Future<Map<KycType, KycDossier>> fetchDossiers() async {
    final dossiers = await _remote.fetchDossiers();
    return {for (final dto in dossiers) dto.toEntity().type: dto.toEntity()};
  }

  @override
  Future<KycDossier> uploadPiece({required KycType type, required KycPieceType piece, required String filePath}) async {
    try {
      final dto = await _remote.uploadPiece(type: type.apiValue, piece: piece.apiValue, filePath: filePath);
      return dto.toEntity();
    } finally {
      // Succès ou échec : la pièce ne reste jamais sur l'appareil (données sensibles).
      await _capture.discard(filePath);
    }
  }

  @override
  Future<KycDossier> submit(KycType type) async => (await _remote.submit(type.apiValue)).toEntity();
}
