import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kovoit/core/network/api_exception.dart';
import 'package:kovoit/core/services/photo_capture_service.dart';
import 'package:kovoit/features/auth/domain/entities/app_user.dart';
import 'package:kovoit/features/kyc/data/datasources/kyc_remote_data_source.dart';
import 'package:kovoit/features/kyc/data/dto/kyc_dossier_dto.dart';
import 'package:kovoit/features/kyc/data/repositories/kyc_repository_impl.dart';
import 'package:kovoit/features/kyc/domain/entities/kyc_dossier.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_app.dart';

class _MockRemote extends Mock implements KycRemoteDataSource {}

/// Dossier conducteur : identité et assurance fournies, le reste manquant.
const _dossier = KycDossierDto(
  type: 'conducteur',
  statut: 'non_verifie',
  pieces: [
    KycPieceDto(typePiece: 'assurance'),
    KycPieceDto(typePiece: 'identite'),
    KycPieceDto(typePiece: 'piece_inconnue'),
  ],
  piecesManquantes: ['permis', 'photo_vehicule', 'selfie'],
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

  test('pièces fournies et manquantes, dans l’ordre d’affichage', () {
    final dossier = _dossier.toEntity();

    expect(dossier.pieces.map((p) => p.type), [
      KycSlot.identite,
      KycSlot.selfie,
      KycSlot.permis,
      KycSlot.vehiculeDocument,
      KycSlot.photoVehicule,
    ]);
    expect(dossier.providedCount, 2, reason: 'les types de pièce inconnus sont ignorés');
    expect(dossier.pieces[3].providedAs, KycPieceType.assurance, reason: 'l’assurance remplace la carte grise');
    expect(dossier.nextMissing?.type, KycSlot.selfie);
    expect(dossier.isComplete, isFalse);
    expect(dossier.isEditable, isTrue);
  });

  test('motif de rejet vide → aucun motif', () {
    const rejete = KycDossierDto(type: 'passager', statut: 'rejete', piecesManquantes: ['identite', 'selfie']);
    final dossier = rejete.toEntity();

    expect(dossier.status, KycStatus.rejete);
    expect(dossier.motifRejet, isNull);
  });

  test('la pièce est supprimée de l’appareil après un envoi réussi', () async {
    when(() => remote.uploadPiece(type: 'conducteur', piece: 'assurance', filePath: 'assurance.jpg'))
        .thenAnswer((_) async => _dossier);

    await repository.uploadPiece(type: KycType.conducteur, piece: KycPieceType.assurance, filePath: 'assurance.jpg');

    expect(capture.discarded, ['assurance.jpg']);
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

  test('ImagePickerCaptureService.discard supprime réellement le fichier', () async {
    final dir = await Directory.systemTemp.createTemp('kovoit_kyc_test');
    addTearDown(() => dir.delete(recursive: true));
    final photo = await File('${dir.path}/piece.jpg').writeAsBytes([1, 2, 3]);

    await ImagePickerCaptureService().discard(photo.path);
    await ImagePickerCaptureService().discard(photo.path); // déjà supprimé : sans erreur

    expect(await photo.exists(), isFalse);
  });
}
