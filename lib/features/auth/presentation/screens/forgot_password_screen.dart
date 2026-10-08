import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_error.dart';

/// Mot de passe oublié (absent des maquettes) : envoi d'un lien de réinitialisation par e-mail.
/// Le message de confirmation est identique que l'e-mail existe ou non (pas de fuite d'information).
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _submitting = false;
  bool _sent = false;

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
      await ref.read(authRepositoryProvider).requestPasswordReset(_email.text);
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      if (mounted) showAuthError(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const KovoitAppBar(),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            const ScreenHeader(
              title: 'Mot de passe oublié',
              subtitle: 'Indiquez votre e-mail : nous vous enverrons un lien pour choisir un nouveau mot de passe.',
            ),
            const SizedBox(height: AppSpacing.xl),
            if (_sent)
              const InfoBanner(
                icon: Icons.mark_email_read_outlined,
                title: 'Si un compte existe avec cet e-mail, un lien de réinitialisation vient d’être envoyé.',
              )
            else ...[
              KovoitTextField(
                label: 'Adresse e-mail',
                hint: 'nom@exemple.com',
                controller: _email,
                prefixIcon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                validator: Validators.email,
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(label: 'Envoyer le lien', isLoading: _submitting, onPressed: _submit),
            ],
          ],
        ),
      ),
    );
  }
}
