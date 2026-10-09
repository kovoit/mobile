import 'dart:io';

import 'package:image_picker/image_picker.dart';

enum CaptureSource { camera, frontCamera, gallery }

/// Prise de photo d'une pièce. Le service crée un fichier temporaire et le supprime ensuite.
abstract interface class DocumentCaptureService {
  /// Chemin du fichier temporaire, ou `null` si l'utilisateur annule.
  Future<String?> capture(CaptureSource source);

  /// Supprime le fichier temporaire (claude.md §1.6 : aucune copie des pièces après envoi).
  Future<void> discard(String path);
}

class ImagePickerCaptureService implements DocumentCaptureService {
  ImagePickerCaptureService([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<String?> capture(CaptureSource source) async {
    final file = await _picker.pickImage(
      source: source == CaptureSource.gallery ? ImageSource.gallery : ImageSource.camera,
      preferredCameraDevice: source == CaptureSource.frontCamera ? CameraDevice.front : CameraDevice.rear,
      // Lisible par l'administrateur tout en limitant le poids envoyé sur réseau mobile.
      maxWidth: 1600,
      imageQuality: 80,
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
