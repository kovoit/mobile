import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/providers/session_controller.dart';

/// Suppression du compte (exigence Google Play / App Store) : explications, confirmation
/// « SUPPRIMER », raisons du refus renvoyées par le backend s'il reste quelque chose en cours.
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _confirmation = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(sessionControllerProvider.notifier).deleteAccount(_confirmation.text);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: KovoitAppBar(onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          const ScreenHeader(title: 'Supprimer mon compte', subtitle: 'Cette action est définitive.'),
          const SizedBox(height: AppSpacing.md),
          const KovoitCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ce qui est effacé', style: AppTextStyles.cardTitle),
                SizedBox(height: AppSpacing.xs),
                Text(
                  '• Votre nom, votre email, votre téléphone et vos photos.\n'
                  '• Vos pièces d’identité et documents de vérification.\n'
                  '• Vos notifications et la connexion de vos téléphones.',
                  style: AppTextStyles.body,
                ),
                SizedBox(height: AppSpacing.md),
                Text('Ce qui est conservé, sans votre identité', style: AppTextStyles.cardTitle),
                SizedBox(height: AppSpacing.xs),
                Text(
                  'L’historique des trajets et des paiements, rattaché à un compte anonyme : il est '
                  'nécessaire aux autres utilisateurs et aux obligations comptables de Kovoit.',
                  style: AppTextStyles.body,
                ),
                SizedBox(height: AppSpacing.md),
                Text(
                  'Avant de supprimer : retirez le solde de votre portefeuille et terminez ou annulez '
                  'vos réservations et trajets en cours.',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          KovoitTextField(
            controller: _confirmation,
            label: 'Saisissez SUPPRIMER pour confirmer',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_error != null) ...[
            InfoBanner(
              icon: Icons.error_outline_rounded,
              tone: InfoBannerTone.error,
              title: 'Suppression impossible pour le moment',
              subtitle: _error,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: _busy || _confirmation.text.trim().toUpperCase() != 'SUPPRIMER' ? null : _delete,
            child: Text(_busy ? 'Suppression…' : 'Supprimer définitivement mon compte'),
          ),
        ],
      ),
    );
  }
}
