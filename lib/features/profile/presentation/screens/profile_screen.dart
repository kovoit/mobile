import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/env.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/providers/session_controller.dart';

/// Profil minimal (S1) : identité, téléphone vérifié, déconnexion.
/// KYC et bascule de mode arrivent en S2 / S5.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _loggingOut = false;

  Future<void> _logout() async {
    setState(() => _loggingOut = true);
    await ref.read(sessionControllerProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionControllerProvider).value;
    return Scaffold(
      appBar: const KovoitAppBar(showBack: false),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          const ScreenHeader(title: 'Profil', subtitle: 'Votre compte et votre vérification.'),
          const SizedBox(height: AppSpacing.xl),
          if (user != null)
            KovoitCard(
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
                        if (user.telephoneVerifie)
                          const StatusChip(label: 'Téléphone vérifié', tone: StatusTone.success, icon: Icons.check_rounded),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          const InfoBanner(
            icon: Icons.construction_rounded,
            tone: InfoBannerTone.accent,
            title: 'Vérification d’identité',
            subtitle: 'Prévue au sprint S2.',
          ),
          const SizedBox(height: AppSpacing.xl),
          if (Env.isDev) ...[
            PrimaryButton.outlined(
              label: 'Catalogue des composants',
              onPressed: () => context.push(Routes.componentCatalog),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
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
