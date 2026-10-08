import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/kovoit_logo.dart';
import '../providers/session_controller.dart';
import '../widgets/auth_error.dart';

/// Écran Figma « Splash ». Affiché pendant la restauration de la session ;
/// la sortie est gérée par le routeur (auth_guard). En cas d'échec (réseau), propose « Réessayer ».
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..forward();

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    final error = session.hasError && !session.isLoading ? session.error : null;

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
              if (error != null)
                _RetryPanel(
                  message: authErrorMessage(error),
                  onRetry: () {
                    _progress.forward(from: 0);
                    ref.read(sessionControllerProvider.notifier).retry();
                  },
                )
              else ...[
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
              ],
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _RetryPanel extends StatelessWidget {
  const _RetryPanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(color: Colors.white),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Réessayer'),
        ),
      ],
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
