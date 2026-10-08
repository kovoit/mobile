import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/session_controller.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/otp_verification_screen.dart';
import '../../features/auth/presentation/screens/phone_number_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/shell/presentation/screens/component_catalog_screen.dart';
import '../../features/shell/presentation/screens/home_shell.dart';
import '../../features/shell/presentation/screens/placeholder_screen.dart';
import '../config/env.dart';
import 'auth_guard.dart';
import 'routes.dart';

/// Routeur de l'application. Les redirections d'accès sont centralisées dans [authRedirect].
final appRouterProvider = Provider<GoRouter>((ref) {
  // Relance l'évaluation des redirections à chaque changement de session.
  final sessionChanges = ValueNotifier<int>(0);
  ref.listen(sessionControllerProvider, (_, _) => sessionChanges.value++);
  ref.onDispose(sessionChanges.dispose);

  return GoRouter(
    initialLocation: Routes.splash,
    debugLogDiagnostics: Env.isDev,
    refreshListenable: sessionChanges,
    redirect: (context, state) => authRedirect(ref.read(sessionControllerProvider), state.matchedLocation),
    routes: [
      GoRoute(path: Routes.splash, builder: (context, state) => const SplashScreen()),
      GoRoute(path: Routes.login, builder: (context, state) => const LoginScreen()),
      GoRoute(path: Routes.register, builder: (context, state) => const RegisterScreen()),
      GoRoute(path: Routes.forgotPassword, builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(path: Routes.phone, builder: (context, state) => const PhoneNumberScreen()),
      GoRoute(path: Routes.otp, builder: (context, state) => const OtpVerificationScreen()),
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
              GoRoute(path: Routes.profile, builder: (context, state) => const ProfileScreen()),
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
