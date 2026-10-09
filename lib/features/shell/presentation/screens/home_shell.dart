import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/access_policy.dart';
import '../../../auth/presentation/providers/session_controller.dart';

/// Coque principale, barre du bas des maquettes.
/// - 1er onglet selon le mode : « Rechercher » (passager) ou « Publier » (conducteur) ;
/// - macaron orange sur « Profil » tant que le KYC attend une action.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionControllerProvider).value;
    final driver = user?.isDriverMode ?? false;
    final kycAlert = user != null && AccessPolicy.needsKycAttention(user);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) => navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          ),
          destinations: [
            NavigationDestination(
              icon: Icon(driver ? Icons.add_road_rounded : Icons.search_rounded),
              label: driver ? 'Publier' : 'Rechercher',
            ),
            const NavigationDestination(icon: Icon(Icons.route_outlined), label: 'Mes trajets'),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: kycAlert,
                smallSize: 10,
                backgroundColor: AppColors.accent,
                child: const Icon(Icons.person_outline_rounded),
              ),
              label: 'Profil',
              tooltip: kycAlert ? 'Profil : vérification d’identité à faire' : 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
