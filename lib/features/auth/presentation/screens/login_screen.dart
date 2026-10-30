import 'dart:async';

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
import '../providers/email_verification_controller.dart';
import '../providers/password_reset_controller.dart';
import '../providers/session_controller.dart';
import '../widgets/auth_error.dart';
import '../widgets/form_error_text.dart';

/// Écran 2 · Connexion (D-68) : e-mail + mot de passe, liens « Mot de passe oublié » et
/// « Créer un compte ». Une adresse non vérifiée (403 `EMAIL_NON_VERIFIE`) ouvre la Vérification.
/// Le mot de passe ne vit que dans le champ (jamais stocké, jamais dans un état Riverpod).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.passwordReset = false});

  /// Retour de « Mot de passe oublié » : message de succès.
  final bool passwordReset;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _submitting = false;
  String? _error;
  Map<String, String> _fieldErrors = const {};

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _error = null;
      _fieldErrors = const {};
    });
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      // Succès : le routeur ouvre l'accueil (ou le profil à compléter d'un compte ancien).
      await ref.read(sessionControllerProvider.notifier).login(email: _email.text, password: _password.text);
    } catch (e) {
      if (!mounted) return;
      if (authErrorCode(e) == 'EMAIL_NON_VERIFIE') {
        ref.read(emailVerificationControllerProvider.notifier).startFromLogin(_email.text);
        _password.clear();
        unawaited(context.push(Routes.emailVerification));
        return;
      }
      setState(() {
        _fieldErrors = authFieldErrors(e);
        _error = _fieldErrors.isEmpty ? authErrorMessage(e) : null;
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _openForgotPassword() {
    ref.read(passwordResetControllerProvider.notifier).restart();
    context.push(Routes.forgotPassword);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Form(
            key: _formKey,
            child: AutofillGroup(
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
                  if (widget.passwordReset) ...[
                    const InfoBanner(
                      icon: Icons.check_circle_outline_rounded,
                      title: 'Mot de passe modifié',
                      subtitle: 'Connectez-vous avec votre nouveau mot de passe.',
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
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
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          validator: Validators.email,
                          errorText: _fieldErrors['email'],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        KovoitTextField(
                          label: 'Mot de passe',
                          hint: 'Votre mot de passe',
                          controller: _password,
                          prefixIcon: Icons.lock_outline_rounded,
                          isPassword: true,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          validator: (v) => Validators.required(v, message: 'Le mot de passe est obligatoire.'),
                          errorText: _fieldErrors['mot_de_passe'],
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _submitting ? null : _openForgotPassword,
                            child: const Text('Mot de passe oublié ?'),
                          ),
                        ),
                        if (_error != null) ...[
                          FormErrorText(_error!),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                        PrimaryButton(
                          label: 'Se connecter',
                          icon: Icons.arrow_forward_rounded,
                          isLoading: _submitting,
                          onPressed: _submit,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('Pas encore de compte ?', style: AppTextStyles.subtitle),
                      TextButton(
                        onPressed: _submitting ? null : () => context.push(Routes.register),
                        child: Text(
                          'Créer un compte',
                          style: AppTextStyles.label.copyWith(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  if (Env.useMockApi) ...[
                    const SizedBox(height: AppSpacing.md),
                    const InfoBanner(
                      icon: Icons.science_outlined,
                      tone: InfoBannerTone.accent,
                      title: 'Mode démo (API simulée)',
                      subtitle: 'Passager : ${DemoAccount.email} · Conducteur : ${DemoAccount.driverEmail}. '
                          'Mot de passe : ${DemoAccount.password}. Code e-mail : ${DemoAccount.otpCode}.',
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
