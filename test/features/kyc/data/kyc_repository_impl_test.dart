import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kovoit/core/network/api_exception.dart';
import 'package:kovoit/features/kyc/data/datasources/kyc_remote_data_source.dart';
import 'package:kovoit/features/kyc/data/dto/kyc_dossier_dto.dart';
import 'package:kovoit/features/kyc/data/repositories/kyc_repository_impl.dart';
import 'package:kovoit/features/kyc/data/services/document_capture_service.dart';
import 'package:kovoit/features/kyc/domain/entities/kyc_dossier.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_app.dart';

class _MockRemote extends Mock implements KycRemoteDataSource {}

const _dossier = KycDossierDto(
  type: 'passager',
  statut: 'non_verifie',
  pieces: [
    KycPieceDto(typePiece: 'photo_profil', fournie: true),
    KycPieceDto(typePiece: 'selfie', fournie: false),
    KycPieceDto(typePiece: 'piece_inconnue', fournie: true),
  ],
);

void main() {
  late _MockRemote remote;
  late FakeCaptureService capture;
  late KycRepositoryImpl repository;

  setUp(() {
    remote = _MockRemote();
    capture = FakeCaptureService();
    repository = KycRepositoryImpl(remote, capture);
  });

  test('la pièce est supprimée de l’appareil après un envoi réussi', () async {
    when(() => remote.uploadPiece(type: 'passager', piece: 'selfie', filePath: 'selfie.jpg'))
        .thenAnswer((_) async => _dossier);

    final dossier = await repository.uploadPiece(type: KycType.passager, piece: KycPieceType.selfie, filePath: 'selfie.jpg');

    expect(capture.discarded, ['selfie.jpg']);
    expect(dossier.providedCount, 1);
    expect(dossier.pieces, hasLength(2), reason: 'les types de pièce inconnus sont ignorés');
  });

  test('la pièce est aussi supprimée si l’envoi échoue', () async {
    when(() => remote.uploadPiece(type: any(named: 'type'), piece: any(named: 'piece'), filePath: any(named: 'filePath')))
        .thenThrow(const NetworkApiException());

    await expectLater(
      repository.uploadPiece(type: KycType.passager, piece: KycPieceType.selfie, filePath: 'selfie.jpg'),
      throwsA(isA<NetworkApiException>()),
    );
    expect(capture.discarded, ['selfie.jpg']);
  });

  test('dossier : prochaine pièce manquante et état modifiable', () {
    final dossier = _dossier.toEntity();
    expect(dossier.nextMissing?.type, KycPieceType.selfie);
    expect(dossier.isComplete, isFalse);
    expect(dossier.isEditable, isTrue);
  });

  test('ImagePickerCaptureService.discard supprime réellement le fichier', () async {
    final dir = await Directory.systemTemp.createTemp('kovoit_kyc_test');
    addTearDown(() => dir.delete(recursive: true));
    final photo = await File('${dir.path}/piece.jpg').writeAsBytes([1, 2, 3]);

    await ImagePickerCaptureService().discard(photo.path);
    await ImagePickerCaptureService().discard(photo.path); // déjà supprimé : sans erreur

    expect(await photo.exists(), isFalse);
  });
}
