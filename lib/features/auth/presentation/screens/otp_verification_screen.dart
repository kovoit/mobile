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
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/otp_controller.dart';
import '../providers/session_controller.dart';
import '../widgets/auth_error.dart';

/// Écran Figma « Vérification SMS » : code OTP à 6 chiffres (≠ code de départ à 4 chiffres).
class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({super.key});

  static const int codeLength = 6;

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendIfNeeded());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _sendIfNeeded() {
    final phone = ref.read(sessionControllerProvider).value?.telephone;
    if (phone != null) ref.read(otpControllerProvider.notifier).sendIfNeeded(phone);
  }

  Future<void> _verify() async {
    final code = _code.text;
    if (code.length != OtpVerificationScreen.codeLength) {
      setState(() => _codeError = 'Saisissez les ${OtpVerificationScreen.codeLength} chiffres reçus par SMS.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _verifying = true;
      _codeError = null;
    });
    try {
      await ref.read(sessionControllerProvider.notifier).verifyOtp(code);
      ref.read(otpControllerProvider.notifier).reset();
    } catch (e) {
      if (!mounted) return;
      setState(() => _codeError = authFieldErrors(e)['code'] ?? authErrorMessage(e));
      _code.clear();
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _logout() => ref.read(sessionControllerProvider.notifier).logout();

  @override
  Widget build(BuildContext context) {
    final phone = ref.watch(sessionControllerProvider).value?.telephone;
    final otp = ref.watch(otpControllerProvider);
    final remaining = otp.remaining(ref.read(clockProvider)());

    return Scaffold(
      appBar: KovoitAppBar(onBack: _logout),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          const ScreenHeader(title: 'Vérification SMS', subtitle: 'Une dernière étape pour sécuriser votre numéro.'),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(AppRadius.card)),
              child: const Icon(Icons.mark_chat_read_outlined, size: 36, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Center(child: StatusChip(label: 'INSCRIPTION · CODE SMS', tone: StatusTone.info)),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Saisissez le code à 6 chiffres envoyé au',
            textAlign: TextAlign.center,
            style: AppTextStyles.subtitle,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            phone == null ? '—' : Formatters.phone(phone),
            textAlign: TextAlign.center,
            style: AppTextStyles.title.copyWith(fontSize: 22),
          ),
          Center(
            child: TextButton(
              onPressed: _verifying ? null : () => context.go(Routes.phone),
              child: Text('Modifier mon numéro', style: AppTextStyles.label.copyWith(color: AppColors.textPrimary)),
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
                  length: OtpVerificationScreen.codeLength,
                  hasError: _codeError != null,
                  onChanged: (code) {
                    // Le champ est vidé après un code faux : on garde le message jusqu'à la nouvelle saisie.
                    if (_codeError != null && code.isNotEmpty) setState(() => _codeError = null);
                  },
                  onCompleted: (_) => _verify(),
                ),
                if (_codeError != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _codeError!,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(color: AppColors.error),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                _ResendSection(
                  remaining: remaining,
                  isSending: otp.isSending,
                  error: otp.error,
                  onResend: () => ref.read(otpControllerProvider.notifier).send(),
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: 'Vérifier mon numéro',
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
                  'Ce code vérifie votre téléphone. Il est différent du code de départ à 4 chiffres de vos trajets.',
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

class _ResendSection extends StatelessWidget {
  const _ResendSection({required this.remaining, required this.isSending, required this.error, required this.onResend});

  final Duration remaining;
  final bool isSending;
  final String? error;
  final VoidCallback onResend;

  String get _countdown {
    final minutes = remaining.inMinutes.toString().padLeft(2, '0');
    final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Vous n’avez pas reçu le SMS ?', style: AppTextStyles.subtitle),
        const SizedBox(height: AppSpacing.xxs),
        if (isSending)
          const Text('Envoi du code…', style: AppTextStyles.subtitle)
        else if (remaining > Duration.zero)
          Text('Renvoyer le code dans $_countdown', style: AppTextStyles.subtitle)
        else
          TextButton(onPressed: onResend, child: const Text('Renvoyer le code')),
        if (error != null)
          Text(error!, textAlign: TextAlign.center, style: AppTextStyles.caption.copyWith(color: AppColors.error)),
      ],
    );
  }
}
