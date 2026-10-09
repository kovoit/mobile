import 'package:dio/dio.dart';

import '../../../../core/mock/fake_backend.dart';
import '../../../../core/network/api_exception.dart';
import '../dto/kyc_dossier_dto.dart';

abstract interface class KycRemoteDataSource {
  Future<List<KycDossierDto>> fetchDossiers();

  Future<KycDossierDto> uploadPiece({required String type, required String piece, required String filePath});

  Future<KycDossierDto> submit(String type);
}

class DioKycRemoteDataSource implements KycRemoteDataSource {
  DioKycRemoteDataSource(this._dio);

  final Dio _dio;

  Future<T> _call<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<List<KycDossierDto>> fetchDossiers() => _call(() async {
        final res = await _dio.get<List<dynamic>>('/kyc/dossiers/');
        return [for (final item in res.data!) KycDossierDto.fromJson(item as Map<String, dynamic>)];
      });

  @override
  Future<KycDossierDto> uploadPiece({required String type, required String piece, required String filePath}) =>
      _call(() async {
        final form = FormData.fromMap({
          'type_piece': piece,
          'fichier': await MultipartFile.fromFile(filePath),
        });
        final res = await _dio.post<Map<String, dynamic>>('/kyc/dossiers/$type/pieces/', data: form);
        return KycDossierDto.fromJson(res.data!);
      });

  @override
  Future<KycDossierDto> submit(String type) => _call(() async {
        final res = await _dio.post<Map<String, dynamic>>('/kyc/dossiers/$type/soumettre/');
        return KycDossierDto.fromJson(res.data!);
      });
}

/// Fausse API KYC (`Env.useMockApi`) branchée sur le [FakeBackend] partagé.
class FakeKycRemoteDataSource implements KycRemoteDataSource {
  FakeKycRemoteDataSource(this._backend);

  final FakeBackend _backend;

  @override
  Future<List<KycDossierDto>> fetchDossiers() async {
    await _backend.wait();
    final id = await _backend.currentUserId();
    return [for (final json in _backend.kycDossiersJson(id)) KycDossierDto.fromJson(json)];
  }

  @override
  Future<KycDossierDto> uploadPiece({required String type, required String piece, required String filePath}) async {
    await _backend.wait();
    final id = await _backend.currentUserId();
    final dossier = _backend.kycDossier(id, type);
    if (dossier.statut == 'en_attente' || dossier.statut == 'verifie') {
      throw const ConflictApiException('Ce dossier est déjà envoyé : les pièces ne sont plus modifiables.');
    }
    if (!FakeBackend.kycPieces[type]!.contains(piece)) {
      throw const BadRequestApiException('Type de pièce invalide.');
    }
    dossier.pieces.add(piece);
    return KycDossierDto.fromJson(_backend.kycDossierJson(id, type));
  }

  @override
  Future<KycDossierDto> submit(String type) async {
    await _backend.wait();
    final id = await _backend.currentUserId();
    final dossier = _backend.kycDossier(id, type);
    if (type == 'conducteur' && _backend.kycDossier(id, 'passager').statut == 'non_verifie') {
      throw const ForbiddenApiException('Envoyez d’abord votre dossier passager.');
    }
    if (dossier.pieces.length < FakeBackend.kycPieces[type]!.length) {
      throw const BadRequestApiException('Toutes les pièces sont requises avant l’envoi.');
    }
    dossier
      ..statut = 'en_attente'
      ..motifRejet = null;
    return KycDossierDto.fromJson(_backend.kycDossierJson(id, type));
  }
}
