import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/demo_account.dart';
import '../../../../core/config/env.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/password_reset_controller.dart';
import '../widgets/forgot_password_code_step.dart';
import '../widgets/forgot_password_email_step.dart';

/// Écran 4 bis · Mot de passe oublié (hors Figma, mise en page de la Vérification) :
/// étape 1, e-mail → « Recevoir le code » ; étape 2, code + nouveau mot de passe, puis retour à la
/// Connexion avec un message de succès. Sert aussi aux comptes anciens sans mot de passe (D-69).
class ForgotPasswordScreen extends ConsumerWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reset = ref.watch(passwordResetControllerProvider);
    final controller = ref.read(passwordResetControllerProvider.notifier);

    void leave() {
      controller.restart();
      context.canPop() ? context.pop() : context.go(Routes.login);
    }

    return Scaffold(
      appBar: KovoitAppBar(onBack: reset.codeRequested ? controller.restart : leave),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          const ScreenHeader(title: 'Mot de passe oublié', subtitle: 'Recevez un code par e-mail pour le changer.'),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(AppRadius.card)),
              child: const Icon(Icons.lock_reset_rounded, size: 36, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: StatusChip(
              label: reset.codeRequested ? 'ÉTAPE 2 · NOUVEAU MOT DE PASSE' : 'ÉTAPE 1 · ADRESSE E-MAIL',
              tone: StatusTone.info,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (reset.codeRequested)
            ForgotPasswordCodeStep(
              email: reset.email!,
              onDone: () => context.go(Routes.loginAfterReset),
            )
          else
            const ForgotPasswordEmailStep(),
          if (Env.useMockApi) ...[
            const SizedBox(height: AppSpacing.md),
            const InfoBanner(
              icon: Icons.science_outlined,
              tone: InfoBannerTone.accent,
              title: 'Mode démo : code ${DemoAccount.otpCode}',
              subtitle: 'Compte sans mot de passe : ${DemoAccount.legacyEmail}.',
            ),
          ],
        ],
      ),
    );
  }
}
