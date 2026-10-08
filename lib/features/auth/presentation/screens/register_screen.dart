import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

/// Écran Figma « Inscription » : nom complet, e-mail, téléphone (+228), mot de passe, CGU ; ou Google.
/// Après création, le routeur redirige vers la vérification SMS.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _acceptedTerms = false;
  bool _showTermsError = false;
  bool _submitting = false;
  bool _googleLoading = false;
  Map<String, String> _fieldErrors = const {};

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _fieldErrors = const {};
      _showTermsError = !_acceptedTerms;
    });
    final valid = _formKey.currentState!.validate();
    if (!valid || !_acceptedTerms) return;

    setState(() => _submitting = true);
    try {
      await ref.read(sessionControllerProvider.notifier).register(
            nomComplet: _name.text,
            email: _email.text,
            telephone: Validators.normalizeTogoPhone(_phone.text)!,
            password: _password.text,
          );
    } catch (e) {
      if (!mounted) return;
      setState(() => _fieldErrors = authFieldErrors(e));
      showAuthError(context, e);
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: KovoitLogo(size: 44, framed: true)),
                  const SizedBox(height: AppSpacing.sm),
                  const ScreenHeader(
                    title: 'Créez votre compte',
                    subtitle: 'Remplissez les informations suivantes pour vous enregistrer.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const AuthModeToggle(
                    current: AuthMode.register,
                    loginLabel: 'Se connecter',
                    registerLabel: 'S’inscrire',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  GoogleButton(isLoading: _googleLoading, onPressed: _submitting ? null : _google),
                  const SizedBox(height: AppSpacing.md),
                  const OrDivider(label: 'Ou avec vos informations'),
                  const SizedBox(height: AppSpacing.md),
                  KovoitTextField(
                    label: 'Nom complet',
                    hint: 'Votre nom complet',
                    controller: _name,
                    prefixIcon: Icons.person_outline_rounded,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    validator: _validateFullName,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  KovoitTextField(
                    label: 'Adresse e-mail',
                    hint: 'nom@exemple.com',
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
                    label: 'Numéro de téléphone',
                    hint: '+228 90 00 00 00',
                    controller: _phone,
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))],
                    validator: Validators.togoPhone,
                    errorText: _fieldErrors['telephone'],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  KovoitTextField(
                    label: 'Mot de passe',
                    hint: '••••••••••••',
                    controller: _password,
                    prefixIcon: Icons.lock_outline_rounded,
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: Validators.password,
                    errorText: _fieldErrors['password'],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _TermsCheckbox(
                    value: _acceptedTerms,
                    showError: _showTermsError,
                    onChanged: (v) => setState(() {
                      _acceptedTerms = v;
                      if (v) _showTermsError = false;
                    }),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PrimaryButton(
                    label: 'Créer mon compte',
                    isLoading: _submitting,
                    onPressed: _googleLoading ? null : _submit,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      const Text('Vous avez déjà un compte ? ', style: AppTextStyles.subtitle),
                      GestureDetector(
                        onTap: busy ? null : () => context.go(Routes.login),
                        child: Text('Se connecter', style: AppTextStyles.label.copyWith(color: AppColors.accent)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String? _validateFullName(String? value) {
    final required = Validators.required(value, message: 'Le nom complet est obligatoire.');
    if (required != null) return required;
    if (value!.trim().split(RegExp(r'\s+')).length < 2) return 'Indiquez votre prénom et votre nom.';
    return null;
  }
}

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({required this.value, required this.showError, required this.onChanged});

  final bool value;
  final bool showError;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: value,
                onChanged: (v) => onChanged(v ?? false),
                activeColor: AppColors.primary,
                side: BorderSide(color: showError ? AppColors.error : AppColors.border, width: 1.5),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: AppSpacing.xxs),
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'J’accepte les Conditions d’utilisation et la Politique de confidentialité.',
                    style: AppTextStyles.caption,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showError)
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.sm, top: AppSpacing.xxs),
            child: Text(
              'Vous devez accepter les conditions pour créer un compte.',
              style: AppTextStyles.caption.copyWith(color: AppColors.error),
            ),
          ),
      ],
    );
  }
}
