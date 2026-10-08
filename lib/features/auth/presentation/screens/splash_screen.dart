import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/kovoit_logo.dart';

/// Écran Figma « Splash » : logo dans un halo, slogan, barre de chargement orange.
/// Sprint S1 : la redirection dépendra de la session (connexion, OTP, KYC).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.duration = const Duration(milliseconds: 1800)});

  final Duration duration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _progress = AnimationController(vsync: this, duration: widget.duration)
    ..forward().whenComplete(_goNext);

  void _goNext() {
    if (mounted) context.go(Routes.search);
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            children: [
              const Spacer(flex: 3),
              const _LogoHalo(),
              const SizedBox(height: AppSpacing.xl),
              Text('Kovoït', style: AppTextStyles.display.copyWith(color: Colors.white, fontSize: 34)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Même trajet, moins cher',
                style: AppTextStyles.body.copyWith(color: Colors.white.withValues(alpha: 0.8)),
              ),
              const Spacer(flex: 4),
              AnimatedBuilder(
                animation: _progress,
                builder: (context, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: _progress.value,
                    minHeight: 5,
                    color: AppColors.accent,
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                "Chargement de l'expérience",
                style: AppTextStyles.caption.copyWith(color: Colors.white.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoHalo extends StatelessWidget {
  const _LogoHalo();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Container(
        width: 180,
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.white.withValues(alpha: 0.15), blurRadius: 40, spreadRadius: 6)],
        ),
        child: const KovoitLogo(size: 120),
      ),
    );
  }
}
