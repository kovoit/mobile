import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/kyc_dossier.dart';
import 'kyc_labels.dart';

/// Ligne d'une pièce KYC : icône, libellé, statut « Terminé » / « À capturer » / « À ajouter ».
class KycPieceCard extends StatelessWidget {
  const KycPieceCard({super.key, required this.piece, required this.isUploading, this.onTap});

  final KycPiece piece;
  final bool isUploading;

  /// `null` si le dossier n'est plus modifiable.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final type = piece.type;
    final hint = type.hint;
    final description = piece.provided ? 'Ajoutée · $hint' : hint[0].toUpperCase() + hint.substring(1);

    return KovoitCard(
      onTap: isUploading ? null : onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: AppColors.fieldFill, borderRadius: BorderRadius.circular(AppRadius.field)),
            child: Icon(type.icon, color: AppColors.textPrimary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xxs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(type.title, style: AppTextStyles.cardTitle),
                    _status(),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(description, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _status() {
    if (isUploading) {
      return const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (piece.provided) {
      return const StatusChip(label: 'Terminé', tone: StatusTone.success, icon: Icons.check_rounded);
    }
    return piece.type.requiresLiveCapture
        ? const StatusChip(label: 'À capturer', tone: StatusTone.warning, icon: Icons.photo_camera_outlined)
        : const StatusChip(label: 'À ajouter', tone: StatusTone.warning, icon: Icons.add_rounded);
  }
}
