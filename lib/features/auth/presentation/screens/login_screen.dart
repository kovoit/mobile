import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/demo_account.dart';
import '../../../../core/config/env.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/otp_controller.dart';
import '../widgets/auth_error.dart';

/// Connexion sans mot de passe : l'utilisateur saisit son e-mail et reçoit un code à 6 chiffres.
/// Le même écran sert à la connexion et à l'inscription (compte créé au premier code valide).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: ref.read(otpControllerProvider).email ?? '');
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(otpControllerProvider.notifier).request(_email.text);
      if (mounted) context.go(Routes.otp);
    } catch (e) {
      if (mounted) showAuthError(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.xl),
                const KovoitLogo(size: 52, framed: true),
                const SizedBox(height: AppSpacing.md),
                const ScreenHeader(
                  title: 'Kovoit',
                  subtitle: 'Connectez-vous pour commencer votre trajet',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                KovoitCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      KovoitTextField(
                        label: 'Adresse e-mail',
                        hint: 'votre@email.com',
                        controller: _email,
                        prefixIcon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.email],
                        validator: Validators.email,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const Text(
                        'Nous vous envoyons un code à 6 chiffres. Pas encore de compte ? Il sera créé automatiquement.',
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      PrimaryButton(
                        label: 'Recevoir le code',
                        icon: Icons.arrow_forward_rounded,
                        isLoading: _submitting,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
                if (Env.useMockApi) ...[
                  const SizedBox(height: AppSpacing.lg),
                  const InfoBanner(
                    icon: Icons.science_outlined,
                    tone: InfoBannerTone.accent,
                    title: 'Mode démo (API simulée)',
                    subtitle: 'Passager : ${DemoAccount.email} · Conducteur : ${DemoAccount.driverEmail}. '
                        'Code : ${DemoAccount.otpCode}. Une autre adresse crée un nouveau compte.',
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
