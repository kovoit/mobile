import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/password_reset_controller.dart';
import 'auth_error.dart';
import 'form_error_text.dart';

/// Étape 1 : adresse e-mail. La réponse est la même que le compte existe ou non.
class ForgotPasswordEmailStep extends ConsumerStatefulWidget {
  const ForgotPasswordEmailStep({super.key});

  @override
  ConsumerState<ForgotPasswordEmailStep> createState() => _ForgotPasswordEmailStepState();
}

class _ForgotPasswordEmailStepState extends ConsumerState<ForgotPasswordEmailStep> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _submitting = false;
  String? _error;
  Map<String, String> _fieldErrors = const {};

  @override
  void dispose() {
    _email.dispose();
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
      await ref.read(passwordResetControllerProvider.notifier).request(_email.text);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _fieldErrors = authFieldErrors(e);
        _error = _fieldErrors.isEmpty ? authErrorMessage(e) : null;
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return KovoitCard(
      child: Form(
        key: _formKey,
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
              errorText: _fieldErrors['email'],
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Si un compte existe avec cette adresse, vous recevrez un code à 6 chiffres.',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: AppSpacing.md),
            if (_error != null) ...[
              FormErrorText(_error!),
              const SizedBox(height: AppSpacing.sm),
            ],
            PrimaryButton(
              label: 'Recevoir le code',
              icon: Icons.arrow_forward_rounded,
              isLoading: _submitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
