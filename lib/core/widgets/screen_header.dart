import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Grand titre d'écran + sous-titre gris (« Rechercher un trajet » / « Le même chemin, à plusieurs. »).
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.title, this.subtitle, this.textAlign = TextAlign.start});

  final String title;
  final String? subtitle;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final centered = textAlign == TextAlign.center;
    return Column(
      crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.display, textAlign: textAlign),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.xxs + 2),
          Text(subtitle!, style: AppTextStyles.subtitle, textAlign: textAlign),
        ],
      ],
    );
  }
}
