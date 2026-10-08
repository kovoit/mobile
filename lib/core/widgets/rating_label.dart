import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Note moyenne affichée « 4.9 ★ ». La moyenne est calculée par l'API.
/// L'étoile est une icône : la police Plus Jakarta Sans ne contient pas le glyphe ★.
class RatingLabel extends StatelessWidget {
  const RatingLabel({super.key, required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    final value = rating.toStringAsFixed(1);
    return Semantics(
      label: 'Note $value sur 5',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: AppTextStyles.cardTitle.copyWith(fontSize: 15)),
          const SizedBox(width: 2),
          const Icon(Icons.star_rounded, size: 17, color: AppColors.textPrimary),
        ],
      ),
    );
  }
}
