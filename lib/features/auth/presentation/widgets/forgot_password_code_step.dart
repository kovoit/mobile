import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/clock.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/password_reset_controller.dart';
import 'auth_error.dart';
import 'form_error_text.dart';
import 'resend_code_section.dart';

/// Étape 2 : code reçu par e-mail, nouveau mot de passe et confirmation, renvoi après le délai.
/// Le mot de passe ne vit que dans les champs de cette étape.
class ForgotPasswordCodeStep extends ConsumerStatefulWidget {
  const ForgotPasswordCodeStep({super.key, required this.email, required this.onDone});

  static const int codeLength = 6;

  final String email;

  /// Réinitialisation réussie (aucun jeton) : retour à la Connexion.
  final VoidCallback onDone;

  @override
  ConsumerState<ForgotPasswordCodeStep> createState() => _ForgotPasswordCodeStepState();
}

class _ForgotPasswordCodeStepState extends ConsumerState<ForgotPasswordCodeStep> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  Timer? _ticker;
  bool _submitting = false;
  String? _codeError;
  String? _error;
  Map<String, String> _fieldErrors = const {};

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _code.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final codeValid = _code.text.length == ForgotPasswordCodeStep.codeLength;
    setState(() {
      _error = null;
      _fieldErrors = const {};
      _codeError = codeValid ? null : 'Saisissez les ${ForgotPasswordCodeStep.codeLength} chiffres reçus par e-mail.';
    });
    final formValid = _formKey.currentState!.validate();
    if (!formValid || !codeValid) return;
    setState(() => _submitting = true);
    try {
      await ref.read(passwordResetControllerProvider.notifier).reset(code: _code.text, password: _password.text);
      if (mounted) widget.onDone();
    } catch (e) {
      if (!mounted) return;
      final fields = authFieldErrors(e);
      setState(() {
        _fieldErrors = fields;
        if (authErrorCode(e) == 'CODE_OTP_INVALIDE') {
          _codeError = fields['code'] ?? authErrorMessage(e);
          _code.clear();
        } else if (fields.isEmpty) {
          _error = authErrorMessage(e);
        }
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reset = ref.watch(passwordResetControllerProvider);
    final remaining = reset.remaining(ref.read(clockProvider)());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Saisissez le code à 6 chiffres envoyé à', textAlign: TextAlign.center, style: AppTextStyles.subtitle),
        const SizedBox(height: AppSpacing.xs),
        Text(widget.email, textAlign: TextAlign.center, style: AppTextStyles.title),
        Center(
          child: TextButton(
            onPressed: _submitting ? null : ref.read(passwordResetControllerProvider.notifier).restart,
            child: Text('Modifier mon e-mail', style: AppTextStyles.label.copyWith(color: AppColors.textPrimary)),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        KovoitCard(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Code reçu par e-mail', style: AppTextStyles.label),
                const SizedBox(height: AppSpacing.sm),
                OtpCodeInput(
                  controller: _code,
                  length: ForgotPasswordCodeStep.codeLength,
                  hasError: _codeError != null,
                  onChanged: (code) {
                    if (_codeError != null && code.isNotEmpty) setState(() => _codeError = null);
                  },
                ),
                if (_codeError != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  FormErrorText(_codeError!),
                ],
                const SizedBox(height: AppSpacing.md),
                ResendCodeSection(
                  remaining: remaining,
                  isSending: reset.isSending,
                  error: reset.error,
                  onResend: () => ref.read(passwordResetControllerProvider.notifier).resend(),
                ),
                const SizedBox(height: AppSpacing.md),
                KovoitTextField(
                  label: 'Nouveau mot de passe',
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
                if (_error != null) ...[
                  FormErrorText(_error!),
                  const SizedBox(height: AppSpacing.sm),
                ],
                PrimaryButton(
                  label: 'Changer mon mot de passe',
                  isLoading: _submitting,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
