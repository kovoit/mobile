import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/env.dart';
import '../../../../core/mock/fake_backend.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/domain/access_policy.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/session_controller.dart';
import '../../../kyc/domain/entities/kyc_dossier.dart';
import '../../../kyc/presentation/providers/kyc_providers.dart';
import '../../../kyc/presentation/widgets/access_required_card.dart';
import '../../../kyc/presentation/widgets/kyc_labels.dart';
import '../../../vehicle/presentation/providers/vehicle_providers.dart';
import '../mode_switcher.dart';
import '../widgets/profile_tile.dart';

/// Profil (retour UX du 08/10) : point d'entrée du KYC et du basculement de mode.
/// - macaron orange tant que le KYC passager attend une action ;
/// - bouton « Passer en mode conducteur / passager » ;
/// - dossier conducteur et véhicule.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _loggingOut = false;
  bool _switching = false;

  Future<void> _logout() async {
    setState(() => _loggingOut = true);
    await ref.read(sessionControllerProvider.notifier).logout();
  }

  Future<void> _switchMode(AppUser user) async {
    setState(() => _switching = true);
    try {
      await switchUserMode(context, ref, user);
    } finally {
      if (mounted) setState(() => _switching = false);
    }
  }

  /// Mode démo : simule la décision de l'administrateur sur les dossiers en attente.
  Future<void> _simulateAdmin({required bool approve}) async {
    await ref.read(fakeBackendProvider).simulateAdminDecision(approve: approve);
    ref.invalidate(kycControllerProvider);
    ref.invalidate(myVehicleProvider);
    await ref.read(sessionControllerProvider.notifier).refreshUser();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionControllerProvider).value;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final vehicle = ref.watch(myVehicleProvider).value;
    final kycDenial = AccessPolicy.needsKycAttention(user) ? AccessPolicy.canBook(user) : null;

    return Scaffold(
      appBar: const KovoitAppBar(showBack: false),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          const ScreenHeader(title: 'Profil', subtitle: 'Votre compte, vos vérifications et votre mode.'),
          const SizedBox(height: AppSpacing.lg),
          _IdentityCard(user: user),
          if (user.isSuspended) ...[
            const SizedBox(height: AppSpacing.md),
            AccessRequiredCard(denial: AccessDenial.suspended, suspendedUntil: user.suspenduJusquAu),
          ] else if (kycDenial != null) ...[
            const SizedBox(height: AppSpacing.md),
            AccessRequiredCard(denial: kycDenial),
          ],
          const SizedBox(height: AppSpacing.lg),
          const Text('Vérifications', style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.xs),
          KovoitCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xxs),
            child: Column(
              children: [
                ProfileTile(
                  icon: Icons.verified_user_outlined,
                  title: KycType.passager.title,
                  subtitle: 'Pièce d’identité et selfie : requis pour réserver.',
                  trailing: kycStatusChip(user.kycPassager),
                  showAlert: AccessPolicy.needsKycAttention(user),
                  onTap: () => context.push(Routes.kyc(KycType.passager.apiValue)),
                ),
                const Divider(),
                ProfileTile(
                  icon: Icons.badge_outlined,
                  title: KycType.conducteur.title,
                  subtitle: 'Permis, carte grise ou assurance, photo du véhicule.',
                  trailing: kycStatusChip(user.kycConducteur),
                  onTap: () => context.push(Routes.kyc(KycType.conducteur.apiValue)),
                ),
                const Divider(),
                ProfileTile(
                  icon: Icons.directions_car_filled_outlined,
                  title: 'Mon véhicule',
                  subtitle: vehicle == null ? 'Non déclaré' : '${vehicle.label} · ${vehicle.immatriculation}',
                  trailing: user.vehiculeDeclare
                      ? const StatusChip(label: 'Déclaré', tone: StatusTone.success, icon: Icons.check_rounded)
                      : null,
                  onTap: () => context.push(Routes.vehicle),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text('Mode d’utilisation', style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.xs),
          _ModeCard(user: user, isLoading: _switching, onSwitch: () => _switchMode(user)),
          if (Env.useMockApi) ...[
            const SizedBox(height: AppSpacing.lg),
            _DemoTools(
              onApprove: () => _simulateAdmin(approve: true),
              onReject: () => _simulateAdmin(approve: false),
              onCatalog: () => context.push(Routes.componentCatalog),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton.outlined(
            label: 'Se déconnecter',
            icon: Icons.logout_rounded,
            isLoading: _loggingOut,
            onPressed: _logout,
          ),
        ],
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return KovoitCard(
      child: Row(
        children: [
          UserAvatar(name: user.nomComplet, photoUrl: user.photoUrl, size: 56),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.nomComplet, style: AppTextStyles.cardTitle),
                const SizedBox(height: 2),
                Text(user.email, style: AppTextStyles.caption),
                if (user.telephone != null) Text(Formatters.phone(user.telephone!), style: AppTextStyles.caption),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xxs,
                  children: [
                    if (user.telephoneVerifie)
                      const StatusChip(label: 'Téléphone vérifié', tone: StatusTone.success, icon: Icons.check_rounded),
                    if (user.kycPassager == KycStatus.verifie) const VerifiedBadge(),
                    StatusChip(
                      label: user.isDriverMode ? 'Mode conducteur' : 'Mode passager',
                      tone: StatusTone.info,
                      icon: user.isDriverMode ? Icons.directions_car_outlined : Icons.person_outline_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.user, required this.isLoading, required this.onSwitch});

  final AppUser user;
  final bool isLoading;
  final VoidCallback onSwitch;

  @override
  Widget build(BuildContext context) {
    final driver = user.isDriverMode;
    return KovoitCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(driver ? Icons.directions_car_filled_outlined : Icons.person_outline_rounded, color: AppColors.accent),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  driver
                      ? 'Vous êtes en mode conducteur : vous publiez vos trajets.'
                      : 'Vous êtes en mode passager : vous recherchez et réservez des trajets.',
                  style: AppTextStyles.body,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: driver ? 'Passer en mode passager' : 'Passer en mode conducteur',
            icon: Icons.swap_horiz_rounded,
            isLoading: isLoading,
            onPressed: onSwitch,
          ),
        ],
      ),
    );
  }
}

class _DemoTools extends StatelessWidget {
  const _DemoTools({required this.onApprove, required this.onReject, required this.onCatalog});

  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onCatalog;

  @override
  Widget build(BuildContext context) {
    return KovoitCard(
      color: AppColors.accentLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Mode démo (API simulée)', style: AppTextStyles.label),
          const Text('Simule la décision de l’administrateur sur les dossiers en attente.', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              OutlinedButton(
                onPressed: onApprove,
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                child: const Text('Valider les dossiers'),
              ),
              OutlinedButton(
                onPressed: onReject,
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                child: const Text('Refuser les dossiers'),
              ),
              OutlinedButton(
                onPressed: onCatalog,
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                child: const Text('Composants'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
