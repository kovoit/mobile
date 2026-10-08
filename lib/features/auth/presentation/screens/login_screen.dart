import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/demo_account.dart';
import '../../../../core/config/env.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/session_controller.dart';
import '../widgets/auth_error.dart';
import '../widgets/auth_mode_toggle.dart';
import '../widgets/google_button.dart';
import '../widgets/or_divider.dart';

/// Écran Figma « Connexion » : email + mot de passe, ou Google.
/// La redirection après succès est faite par le routeur (auth_guard).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _submitting = false;
  bool _googleLoading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(sessionControllerProvider.notifier).login(email: _email.text, password: _password.text);
    } catch (e) {
      if (mounted) showAuthError(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _google() async {
    setState(() => _googleLoading = true);
    try {
      await ref.read(sessionControllerProvider.notifier).signInWithGoogle();
    } catch (e) {
      if (mounted) showAuthError(context, e);
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _submitting || _googleLoading;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: AutofillGroup(
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
                  const SizedBox(height: AppSpacing.lg),
                  const AuthModeToggle(current: AuthMode.login),
                  const SizedBox(height: AppSpacing.lg),
                  KovoitCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        KovoitTextField(
                          label: 'Email',
                          hint: 'votre@email.com',
                          controller: _email,
                          prefixIcon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          validator: Validators.email,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        KovoitTextField(
                          label: 'Mot de passe',
                          hint: '••••••••',
                          controller: _password,
                          prefixIcon: Icons.lock_outline_rounded,
                          isPassword: true,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          validator: (v) => Validators.required(v, message: 'Le mot de passe est obligatoire.'),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: busy ? null : () => context.push(Routes.forgotPassword),
                            child: const Text('Mot de passe oublié ?'),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        PrimaryButton(
                          label: 'Se connecter',
                          isLoading: _submitting,
                          onPressed: _googleLoading ? null : _submit,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        const OrDivider(),
                        const SizedBox(height: AppSpacing.lg),
                        GoogleButton(isLoading: _googleLoading, onPressed: _submitting ? null : _google),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _Footer(onTap: busy ? null : () => context.go(Routes.register)),
                  if (Env.useMockApi) ...[
                    const SizedBox(height: AppSpacing.lg),
                    const InfoBanner(
                      icon: Icons.science_outlined,
                      tone: InfoBannerTone.accent,
                      title: 'Mode démo (API simulée)',
                      subtitle: 'Compte : ${DemoAccount.email} / ${DemoAccount.password}',
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        const Text('Pas de compte ? ', style: AppTextStyles.subtitle),
        GestureDetector(
          onTap: onTap,
          child: Text('Inscrivez-vous', style: AppTextStyles.label.copyWith(color: AppColors.accent)),
        ),
      ],
    );
  }
}
