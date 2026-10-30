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
import '../../../../core/utils/clock.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/email_verification_controller.dart';
import '../providers/session_controller.dart';
import '../widgets/auth_error.dart';
import '../widgets/form_error_text.dart';
import '../widgets/resend_code_section.dart';

/// Écran 4 · Vérification de l'e-mail : code à 6 chiffres reçu après l'inscription, ou après une
/// connexion refusée par `EMAIL_NON_VERIFIE` (≠ code de départ à 4 chiffres). Le bon code ouvre
/// la session : le routeur affiche l'accueil.
class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  static const int codeLength = 6;

  @override
  ConsumerState<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends ConsumerState<EmailVerificationScreen> {
  final _code = TextEditingController();
  Timer? _ticker;
  bool _verifying = false;
  String? _codeError;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    // Ouvert sans adresse à vérifier (lien direct, redémarrage) : retour à la Connexion.
    if (ref.read(emailVerificationControllerProvider).email == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(Routes.login);
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _back() => context.canPop() ? context.pop() : context.go(Routes.login);

  /// D-75 : « Modifier mon e-mail » = retour à l'inscription avec une autre adresse.
  void _changeEmail() {
    final origin = ref.read(emailVerificationControllerProvider).origin;
    if (origin == VerificationOrigin.registration && context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.register);
    }
  }

  Future<void> _verify() async {
    if (_verifying) return;
    final verification = ref.read(emailVerificationControllerProvider.notifier);
    final email = ref.read(emailVerificationControllerProvider).email;
    final code = _code.text;
    if (email == null) return;
    if (code.length != EmailVerificationScreen.codeLength) {
      setState(() => _codeError = 'Saisissez les ${EmailVerificationScreen.codeLength} chiffres reçus par e-mail.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _verifying = true;
      _codeError = null;
    });
    try {
      await ref.read(sessionControllerProvider.notifier).verifyEmail(email: email, code: code);
      // Notifier lu avant l'attente : l'écran peut déjà être démonté par la redirection.
      verification.reset();
    } catch (e) {
      if (!mounted) return;
      setState(() => _codeError = authFieldErrors(e)['code'] ?? authErrorMessage(e));
      _code.clear();
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final verification = ref.watch(emailVerificationControllerProvider);
    final remaining = verification.remaining(ref.read(clockProvider)());

    return Scaffold(
      appBar: KovoitAppBar(onBack: _back),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          const ScreenHeader(title: 'Vérification', subtitle: 'Consultez votre boîte de réception.'),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(AppRadius.card)),
              child: const Icon(Icons.mark_email_read_outlined, size: 36, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Center(child: StatusChip(label: 'VÉRIFICATION · CODE E-MAIL', tone: StatusTone.info)),
          const SizedBox(height: AppSpacing.md),
          const Text('Saisissez le code à 6 chiffres envoyé à', textAlign: TextAlign.center, style: AppTextStyles.subtitle),
          const SizedBox(height: AppSpacing.xs),
          Text(verification.email ?? '—', textAlign: TextAlign.center, style: AppTextStyles.title),
          Center(
            child: TextButton(
              onPressed: _verifying ? null : _changeEmail,
              child: Text('Modifier mon e-mail', style: AppTextStyles.label.copyWith(color: AppColors.textPrimary)),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          KovoitCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Code de vérification', style: AppTextStyles.label),
                const SizedBox(height: AppSpacing.sm),
                OtpCodeInput(
                  controller: _code,
                  length: EmailVerificationScreen.codeLength,
                  hasError: _codeError != null,
                  onChanged: (code) {
                    // Le champ est vidé après un code faux : on garde le message jusqu'à la nouvelle saisie.
                    if (_codeError != null && code.isNotEmpty) setState(() => _codeError = null);
                  },
                  onCompleted: (_) => _verify(),
                ),
                if (_codeError != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  FormErrorText(_codeError!),
                ],
                const SizedBox(height: AppSpacing.md),
                ResendCodeSection(
                  remaining: remaining,
                  isSending: verification.isSending,
                  error: verification.error,
                  onResend: () => ref.read(emailVerificationControllerProvider.notifier).resend(),
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: 'Vérifier mon e-mail',
                  icon: Icons.arrow_forward_rounded,
                  isLoading: _verifying,
                  onPressed: _verify,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.shield_outlined, size: 20, color: AppColors.success),
              SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Ce code est valable 10 minutes. Il est différent du code de départ à 4 chiffres de vos trajets.',
                  style: AppTextStyles.caption,
                ),
              ),
            ],
          ),
          if (Env.useMockApi) ...[
            const SizedBox(height: AppSpacing.md),
            const InfoBanner(
              icon: Icons.science_outlined,
              tone: InfoBannerTone.accent,
              title: 'Mode démo : code ${DemoAccount.otpCode}',
            ),
          ],
        ],
      ),
    );
  }
}
