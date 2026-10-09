import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/domain/access_policy.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/session_controller.dart';
import '../../../kyc/domain/entities/kyc_dossier.dart';
import '../../../kyc/presentation/widgets/access_required_card.dart';
import '../../../kyc/presentation/widgets/kyc_labels.dart';
import '../mode_switcher.dart';

/// Check-list « Devenir conducteur » : affichée quand l'utilisateur demande le mode conducteur
/// sans avoir encore tous les droits (KYC passager + KYC conducteur validés, véhicule déclaré).
class BecomeDriverScreen extends ConsumerStatefulWidget {
  const BecomeDriverScreen({super.key});

  @override
  ConsumerState<BecomeDriverScreen> createState() => _BecomeDriverScreenState();
}

class _BecomeDriverScreenState extends ConsumerState<BecomeDriverScreen> {
  bool _switching = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionControllerProvider).value;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final denial = AccessPolicy.canSwitchToDriver(user);

    return Scaffold(
      appBar: const KovoitAppBar(),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          const ScreenHeader(
            title: 'Devenir conducteur',
            subtitle: 'Partagez votre route, allégez vos dépenses. Trois étapes avant votre premier trajet.',
          ),
          const SizedBox(height: AppSpacing.lg),
          if (denial == AccessDenial.suspended)
            AccessRequiredCard(denial: denial!, suspendedUntil: user.suspenduJusquAu)
          else
            KovoitCard(
              child: Column(
                children: [
                  _Step(
                    number: 1,
                    title: KycType.passager.title,
                    status: user.kycPassager,
                    onTap: () => context.push(Routes.kyc(KycType.passager.apiValue)),
                  ),
                  const Divider(height: AppSpacing.xl),
                  _Step(
                    number: 2,
                    title: KycType.conducteur.title,
                    status: user.kycConducteur,
                    onTap: () => context.push(Routes.kyc(KycType.conducteur.apiValue)),
                  ),
                  const Divider(height: AppSpacing.xl),
                  _Step(
                    number: 3,
                    title: 'Véhicule déclaré',
                    done: user.vehiculeDeclare,
                    onTap: () => context.push(Routes.vehicle),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          if (denial != null && denial != AccessDenial.suspended)
            Text(AccessDenialMessage.of(denial).body, style: AppTextStyles.subtitle),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: 'Passer en mode conducteur',
            icon: Icons.swap_horiz_rounded,
            isLoading: _switching,
            onPressed: denial != null
                ? null
                : () async {
                    setState(() => _switching = true);
                    try {
                      await switchUserMode(context, ref, user);
                    } finally {
                      if (mounted) setState(() => _switching = false);
                    }
                  },
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.title, required this.onTap, this.status, this.done});

  final int number;
  final String title;
  final KycStatus? status;
  final bool? done;
  final VoidCallback onTap;

  bool get _isDone => done ?? status == KycStatus.verifie;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: _isDone ? AppColors.success : AppColors.fieldFill,
            child: _isDone
                ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                : Text('$number', style: AppTextStyles.label),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(title, style: AppTextStyles.label)),
          if (status != null)
            kycStatusChip(status!)
          else if (!_isDone)
            const StatusChip(label: 'À déclarer', tone: StatusTone.warning),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
