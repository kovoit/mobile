import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/shell/presentation/screens/component_catalog_screen.dart';
import '../../features/shell/presentation/screens/home_shell.dart';
import '../../features/shell/presentation/screens/placeholder_screen.dart';
import '../config/env.dart';
import 'routes.dart';

/// Routeur de l'application.
/// Les guards (connexion, OTP, KYC, mode conducteur, compte suspendu) seront ajoutés
/// dans `redirect` à partir du Sprint S1 (voir claude.md §3).
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.splash,
    debugLogDiagnostics: Env.isDev,
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.search,
                builder: (context, state) => const PlaceholderScreen(
                  title: 'Rechercher un trajet',
                  subtitle: 'Le même chemin, à plusieurs. Et moins cher.',
                  sprint: 'S3',
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.myTrips,
                builder: (context, state) => const PlaceholderScreen(
                  title: 'Mes trajets',
                  subtitle: 'Vos réservations et trajets publiés.',
                  sprint: 'S4',
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.profile,
                builder: (context, state) => PlaceholderScreen(
                  title: 'Profil',
                  subtitle: 'Votre compte et votre vérification.',
                  sprint: 'S1–S2',
                  action: Env.isDev
                      ? PlaceholderAction(
                          label: 'Catalogue des composants',
                          onPressed: () => context.push(Routes.componentCatalog),
                        )
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
      if (Env.isDev)
        GoRoute(
          path: Routes.componentCatalog,
          builder: (context, state) => const ComponentCatalogScreen(),
        ),
    ],
    errorBuilder: (context, state) => const Scaffold(
      body: Center(child: Text('Page introuvable.')),
    ),
  );
});
