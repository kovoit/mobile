import 'package:flutter/material.dart';

import '../../../../core/services/photo_capture_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/widgets.dart';

/// Avatar du Profil cliquable (D-19) : badge appareil photo, feuille « Prendre une photo /
/// Choisir dans la galerie », chargement sur l'avatar pendant l'envoi.
/// Le widget ne fait que choisir la source : la prise de vue et l'envoi sont faits par l'écran.
class ProfilePhotoPicker extends StatelessWidget {
  const ProfilePhotoPicker({
    super.key,
    required this.name,
    this.photoUrl,
    required this.isUploading,
    required this.onSourceSelected,
    this.size = 56,
  });

  final String name;
  final String? photoUrl;
  final bool isUploading;
  final ValueChanged<CaptureSource> onSourceSelected;
  final double size;

  Future<void> _chooseSource(BuildContext context) async {
    final source = await showModalBottomSheet<CaptureSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Prendre une photo'),
              // Portrait : caméra frontale proposée par défaut (l'utilisateur peut la changer).
              onTap: () => Navigator.pop(context, CaptureSource.frontCamera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choisir dans la galerie'),
              onTap: () => Navigator.pop(context, CaptureSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null) onSourceSelected(source);
  }

  @override
  Widget build(BuildContext context) {
    final badgeSize = size * 0.4;
    return Semantics(
      button: true,
      label: 'Changer la photo de profil',
      child: GestureDetector(
        onTap: isUploading ? null : () => _chooseSource(context),
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              UserAvatar(name: name, photoUrl: photoUrl, size: size),
              if (isUploading)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withValues(alpha: 0.45)),
                    child: Center(
                      child: SizedBox.square(
                        dimension: size * 0.4,
                        child: const CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.surface),
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: badgeSize,
                  height: badgeSize,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                  child: Icon(Icons.photo_camera_rounded, size: badgeSize * 0.55, color: AppColors.surface),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
