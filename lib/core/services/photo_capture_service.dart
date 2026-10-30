import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

enum CaptureSource { camera, frontCamera, gallery }

/// Prise de photo (pièce KYC, photo de profil). Le service crée un fichier temporaire, réduit à la
/// source, que l'appelant supprime après l'envoi.
abstract interface class PhotoCaptureService {
  /// Chemin du fichier temporaire, ou `null` si l'utilisateur annule.
  Future<String?> capture(CaptureSource source);

  /// Supprime le fichier temporaire (claude.md §1.6 : aucune copie gardée après envoi).
  Future<void> discard(String path);
}

class ImagePickerCaptureService implements PhotoCaptureService {
  ImagePickerCaptureService({ImagePicker? picker, this.maxWidth = 1600, this.imageQuality = 80})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Réglages techniques de compression (le backend reste juge de la taille et des formats).
  final double maxWidth;
  final int imageQuality;

  @override
  Future<String?> capture(CaptureSource source) async {
    final file = await _picker.pickImage(
      source: source == CaptureSource.gallery ? ImageSource.gallery : ImageSource.camera,
      preferredCameraDevice: source == CaptureSource.frontCamera ? CameraDevice.front : CameraDevice.rear,
      maxWidth: maxWidth,
      imageQuality: imageQuality,
    );
    return file?.path;
  }

  @override
  Future<void> discard(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      // Fichier temporaire déjà nettoyé par le système : rien à faire.
    }
  }
}

/// Pièces KYC : lisibles par l'administrateur tout en limitant le poids envoyé sur réseau mobile.
final photoCaptureServiceProvider = Provider<PhotoCaptureService>((ref) => ImagePickerCaptureService());

/// Photo de profil (D-19) : affichée en petit, donc réduite davantage.
final profilePhotoCaptureServiceProvider = Provider<PhotoCaptureService>(
  (ref) => ImagePickerCaptureService(maxWidth: 1024, imageQuality: 80),
);
