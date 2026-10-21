import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/session_controller.dart';
import '../widgets/auth_error.dart';

/// Après la première connexion : prénom, nom et téléphone (`PATCH /moi/`).
/// Obligatoire avant d'accéder à l'application (et exigé par le backend avant tout dossier KYC).
class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _prenom;
  late final TextEditingController _nom;
  late final TextEditingController _phone;
  bool _submitting = false;
  Map<String, String> _fieldErrors = const {};

  @override
  void initState() {
    super.initState();
    final user = ref.read(sessionControllerProvider).value;
    _prenom = TextEditingController(text: user?.prenom ?? '');
    _nom = TextEditingController(text: user?.nom ?? '');
    _phone = TextEditingController(text: user?.telephone?.replaceFirst('+228', '') ?? '');
  }

  @override
  void dispose() {
    _prenom.dispose();
    _nom.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _fieldErrors = const {});
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      // La redirection vers l'accueil est faite par le routeur (profil complet).
      await ref.read(sessionControllerProvider.notifier).completeProfile(
            prenom: _prenom.text,
            nom: _nom.text,
            telephone: Validators.normalizeTogoPhone(_phone.text)!,
          );
    } catch (e) {
      if (!mounted) return;
      setState(() => _fieldErrors = authFieldErrors(e));
      showAuthError(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: KovoitAppBar(onBack: () => ref.read(sessionControllerProvider.notifier).logout()),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            const ScreenHeader(
              title: 'Votre profil',
              subtitle: 'Ces informations sont visibles par les conducteurs et passagers de vos trajets.',
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
              label: 'Numéro de téléphone',
              hint: '+228 90 00 00 00',
              controller: _phone,
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))],
              validator: Validators.togoPhone,
              errorText: _fieldErrors['telephone'],
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(label: 'Continuer', isLoading: _submitting, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
