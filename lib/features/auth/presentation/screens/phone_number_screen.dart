import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/otp_controller.dart';
import '../providers/session_controller.dart';
import '../widgets/auth_error.dart';

/// Saisie / modification du numéro (absent des maquettes) :
/// - compte Google sans numéro ;
/// - lien « Modifier mon numéro » de l'écran Vérification SMS.
class PhoneNumberScreen extends ConsumerStatefulWidget {
  const PhoneNumberScreen({super.key});

  @override
  ConsumerState<PhoneNumberScreen> createState() => _PhoneNumberScreenState();
}

class _PhoneNumberScreenState extends ConsumerState<PhoneNumberScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _phone;
  bool _submitting = false;
  String? _fieldError;

  @override
  void initState() {
    super.initState();
    final current = ref.read(sessionControllerProvider).value?.telephone;
    _phone = TextEditingController(text: current == null ? '' : current.replaceFirst('+228', ''));
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  bool get _hasPhone => ref.read(sessionControllerProvider).value?.hasTelephone ?? false;

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _fieldError = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(sessionControllerProvider.notifier).updatePhone(Validators.normalizeTogoPhone(_phone.text)!);
      ref.read(otpControllerProvider.notifier).reset();
      if (mounted) context.go(Routes.otp);
    } catch (e) {
      if (!mounted) return;
      setState(() => _fieldError = authFieldErrors(e)['telephone']);
      showAuthError(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _back() {
    if (_hasPhone) {
      context.go(Routes.otp);
    } else {
      ref.read(sessionControllerProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: KovoitAppBar(onBack: _back),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            const ScreenHeader(
              title: 'Votre numéro',
              subtitle: 'Nous vous enverrons un code par SMS pour le vérifier.',
            ),
            const SizedBox(height: AppSpacing.xl),
            KovoitTextField(
              label: 'Numéro de téléphone',
              hint: '+228 90 00 00 00',
              controller: _phone,
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))],
              validator: Validators.togoPhone,
              errorText: _fieldError,
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(label: 'Recevoir le code', isLoading: _submitting, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
