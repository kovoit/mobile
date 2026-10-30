import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/cgu.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/registration.dart';
import '../providers/email_verification_controller.dart';
import '../widgets/auth_error.dart';
import '../widgets/form_error_text.dart';
import '../widgets/terms_checkbox.dart';

/// Écran 3 · Inscription (D-68) : prénom, nom, e-mail, téléphone +228, mot de passe et
/// confirmation, CGU. Le mobile ne contrôle que le format ; le backend juge (erreurs sous les champs).
/// Après l'envoi, la Vérification attend le code reçu par e-mail.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _prenom = TextEditingController();
  final _nom = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _termsAccepted = false;
  String? _termsError;
  bool _submitting = false;
  String? _error;
  Map<String, String> _fieldErrors = const {};

  @override
  void dispose() {
    for (final c in [_prenom, _nom, _email, _phone, _password, _confirmation]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _error = null;
      _fieldErrors = const {};
      _termsError = _termsAccepted ? null : 'Acceptez les conditions d’utilisation pour continuer.';
    });
    final formValid = _formKey.currentState!.validate();
    if (!formValid || !_termsAccepted) return;
    setState(() => _submitting = true);
    try {
      await ref.read(emailVerificationControllerProvider.notifier).register(
            Registration(
              prenom: _prenom.text,
              nom: _nom.text,
              email: _email.text,
              telephone: Validators.normalizeTogoPhone(_phone.text)!,
              motDePasse: _password.text,
              cguAcceptees: _termsAccepted,
            ),
          );
      if (!mounted) return;
      unawaited(context.push(Routes.emailVerification));
      // Retour par « Modifier mon e-mail » : identité gardée, mot de passe redemandé.
      _password.clear();
      _confirmation.clear();
    } catch (e) {
      if (!mounted) return;
      final fields = authFieldErrors(e);
      setState(() {
        _fieldErrors = fields;
        _termsError = fields['cgu_acceptees'];
        _error = fields.isEmpty ? authErrorMessage(e) : null;
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: KovoitAppBar(onBack: () => context.canPop() ? context.pop() : context.go(Routes.login)),
      body: Form(
        key: _formKey,
        child: AutofillGroup(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [
              const ScreenHeader(
                title: 'Créer un compte',
                subtitle: 'Vos nom et prénom sont visibles par les conducteurs et passagers de vos trajets.',
              ),
              const SizedBox(height: AppSpacing.xl),
              KovoitTextField(
                label: 'Prénom',
                hint: 'Afi',
                controller: _prenom,
                prefixIcon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.givenName],
                validator: (v) => Validators.required(v, message: 'Le prénom est obligatoire.'),
                errorText: _fieldErrors['prenom'],
              ),
              const SizedBox(height: AppSpacing.md),
              KovoitTextField(
                label: 'Nom',
                hint: 'Amégan',
                controller: _nom,
                prefixIcon: Icons.badge_outlined,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.familyName],
                validator: (v) => Validators.required(v, message: 'Le nom est obligatoire.'),
                errorText: _fieldErrors['nom'],
              ),
              const SizedBox(height: AppSpacing.md),
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
                hint: '8 caractères minimum',
                controller: _password,
                prefixIcon: Icons.lock_outline_rounded,
                isPassword: true,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                validator: Validators.password,
                errorText: _fieldErrors['mot_de_passe'],
              ),
              const SizedBox(height: AppSpacing.md),
              KovoitTextField(
                label: 'Confirmer le mot de passe',
                hint: 'Saisissez-le à nouveau',
                controller: _confirmation,
                prefixIcon: Icons.lock_outline_rounded,
                isPassword: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                validator: (v) => Validators.passwordConfirmation(v, _password.text),
              ),
              const SizedBox(height: AppSpacing.md),
              TermsCheckbox(
                value: _termsAccepted,
                url: Cgu.url,
                error: _termsError,
                onChanged: (v) => setState(() {
                  _termsAccepted = v;
                  _termsError = null;
                }),
              ),
              const SizedBox(height: AppSpacing.md),
              if (_error != null) ...[
                FormErrorText(_error!),
                const SizedBox(height: AppSpacing.sm),
              ],
              PrimaryButton(label: 'Créer mon compte', isLoading: _submitting, onPressed: _submit),
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: TextButton(
                  onPressed: _submitting ? null : () => context.canPop() ? context.pop() : context.go(Routes.login),
                  child: const Text('J’ai déjà un compte : me connecter'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
