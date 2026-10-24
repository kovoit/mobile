import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/session_controller.dart';
import '../widgets/terms_checkbox.dart';

/// Conditions d'utilisation à accepter (compte existant, ou nouvelle version des CGU).
/// Le routeur y renvoie tant qu'elles ne sont pas acceptées.
class AcceptTermsScreen extends ConsumerStatefulWidget {
  const AcceptTermsScreen({super.key});

  @override
  ConsumerState<AcceptTermsScreen> createState() => _AcceptTermsScreenState();
}

class _AcceptTermsScreenState extends ConsumerState<AcceptTermsScreen> {
  bool _accepted = false;
  bool _busy = false;
  String? _error;

  Future<void> _continue() async {
    if (!_accepted) {
      setState(() => _error = 'Cochez la case pour continuer.');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(sessionControllerProvider.notifier).acceptTerms();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = ref.watch(sessionControllerProvider).value?.cguUrl ?? '';
    return Scaffold(
      appBar: KovoitAppBar(onBack: () => ref.read(sessionControllerProvider.notifier).logout()),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          const ScreenHeader(
            title: 'Conditions d’utilisation',
            subtitle: 'Merci de les lire et de les accepter pour continuer.',
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Elles expliquent le partage des frais, le calcul du prix, la commission Kovoit (payée par le '
            'conducteur), les règles d’annulation et d’absence, et la protection de vos données.',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppSpacing.md),
          TermsCheckbox(
            value: _accepted,
            url: url,
            error: _error,
            onChanged: (v) => setState(() {
              _accepted = v;
              _error = null;
            }),
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(label: 'Continuer', isLoading: _busy, onPressed: _continue),
        ],
      ),
    );
  }
}
