import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

enum InfoBannerTone { success, accent, primary }

/// Bandeau d'information des maquettes :
/// - success : « Moins de véhicules. Plus de bonnes rencontres. »
/// - accent : « Prix recommandé : 300 FCFA », « Kodjo arrive dans 3 min »
/// - primary : bloc sombre (« Mes économies ce mois », code de départ)
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.tone = InfoBannerTone.success,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final InfoBannerTone tone;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, iconColor) = switch (tone) {
      InfoBannerTone.success => (AppColors.successLight, AppColors.success, AppColors.success),
      InfoBannerTone.accent => (AppColors.accentLight, AppColors.textPrimary, AppColors.warning),
      InfoBannerTone.primary => (AppColors.primary, Colors.white, AppColors.accent),
    };
    final subtitleColor = switch (tone) {
      InfoBannerTone.success => AppColors.success,
      InfoBannerTone.accent => AppColors.warning,
      InfoBannerTone.primary => Colors.white.withValues(alpha: 0.75),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.label.copyWith(
                    color: foreground,
                    fontWeight: subtitle == null ? FontWeight.w500 : FontWeight.w700,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: AppTextStyles.caption.copyWith(color: subtitleColor)),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
