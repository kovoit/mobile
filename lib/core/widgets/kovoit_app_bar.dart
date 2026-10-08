import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'kovoit_logo.dart';

/// En-tête commun des maquettes : bouton retour, logo + « Kovoit », badge de ville « Lomé ».
class KovoitAppBar extends StatelessWidget implements PreferredSizeWidget {
  const KovoitAppBar({super.key, this.showBack = true, this.onBack, this.city = 'Lomé'});

  final bool showBack;
  final VoidCallback? onBack;
  final String city;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding, vertical: AppSpacing.xs),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: showBack && (onBack != null || canPop)
                  ? _BackButton(onPressed: onBack ?? () => Navigator.of(context).maybePop())
                  : null,
            ),
            const Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  KovoitLogo(size: 28),
                  SizedBox(width: AppSpacing.xs),
                  Text('Kovoit', style: AppTextStyles.cardTitle),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.border.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(city, style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onPressed,
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.chevron_left_rounded, color: AppColors.textPrimary, semanticLabel: 'Retour'),
        ),
      ),
    );
  }
}
