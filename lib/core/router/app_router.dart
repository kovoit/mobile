import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/session_controller.dart';
import '../../features/auth/presentation/screens/complete_profile_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/otp_verification_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/booking/presentation/screens/booking_screen.dart';
import '../../features/booking/presentation/screens/my_trips_screen.dart';
import '../../features/driver/presentation/screens/driver_trip_screen.dart';
import '../../features/kyc/domain/entities/kyc_dossier.dart';
import '../../features/kyc/presentation/screens/kyc_screen.dart';
import '../../features/kyc/presentation/screens/kyc_submitted_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/profile/presentation/screens/become_driver_screen.dart';
import '../../features/report/presentation/report_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/search/domain/entities/search_query.dart';
import '../../features/search/presentation/screens/map_picker_screen.dart';
import '../../features/search/presentation/screens/place_picker_screen.dart';
import '../../features/search/presentation/screens/search_results_screen.dart';
import '../../features/shell/presentation/screens/component_catalog_screen.dart';
import '../../features/shell/presentation/screens/home_screen.dart';
import '../../features/shell/presentation/screens/home_shell.dart';
import '../../features/trip/presentation/screens/trip_detail_screen.dart';
import '../../features/vehicle/presentation/screens/vehicle_form_screen.dart';
import '../config/env.dart';
import 'auth_guard.dart';
import 'routes.dart';

/// Navigateur racine : les sous-écrans du Profil s'ouvrent en plein écran, sans la barre du bas.
final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Routeur de l'application. Les redirections d'accès sont centralisées dans [authRedirect].
final appRouterProvider = Provider<GoRouter>((ref) {
  // Relance l'évaluation des redirections uniquement quand un champ utile à [authRedirect] change.
  // Un rafraîchissement de l'utilisateur (KYC envoyé, véhicule, mode) ne doit pas reconstruire
  // la pile de navigation : il entrerait en concurrence avec un `pop()` en cours.
  final sessionChanges = ValueNotifier<int>(0);
  ref.listen(
    sessionControllerProvider.select(
      (s) => (
        s.isLoading,
        s.hasError,
        s.value == null,
        s.value?.profilComplet,
      ),
    ),
    (_, _) => sessionChanges.value++,
  );
  ref.onDispose(sessionChanges.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: Routes.splash,
    debugLogDiagnostics: Env.isDev,
    refreshListenable: sessionChanges,
    redirect: (context, state) => authRedirect(ref.read(sessionControllerProvider), state.matchedLocation),
    routes: [
      GoRoute(path: Routes.splash, builder: (context, state) => const SplashScreen()),
      GoRoute(path: Routes.login, builder: (context, state) => const LoginScreen()),
      GoRoute(path: Routes.otp, builder: (context, state) => const OtpVerificationScreen()),
      GoRoute(path: Routes.completeProfile, builder: (context, state) => const CompleteProfileScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.home,
                builder: (context, state) => const HomeScreen(),
                routes: [
                  // Résultats : barre du bas visible (maquette « Conducteurs disponibles »).
                  GoRoute(
                    path: Routes.searchResultsSegment,
                    redirect: (context, state) =>
                        SearchQuery.fromQueryParameters(state.uri.queryParameters) == null ? Routes.home : null,
                    builder: (context, state) =>
                        SearchResultsScreen(query: SearchQuery.fromQueryParameters(state.uri.queryParameters)!),
                  ),
                  GoRoute(
                    path: Routes.placePickerSegment,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) =>
                        PlacePickerScreen(field: PlaceField.fromParam(state.uri.queryParameters['champ'])),
                    routes: [
                      GoRoute(
                        path: Routes.mapPickerSegment,
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) => const MapPickerScreen(),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: Routes.tripDetailSegment,
                    parentNavigatorKey: _rootNavigatorKey,
                    redirect: (context, state) =>
                        int.tryParse(state.pathParameters['id'] ?? '') == null ? Routes.home : null,
                    builder: (context, state) => TripDetailScreen(
                      tripId: int.parse(state.pathParameters['id']!),
                      places: (int.tryParse(state.uri.queryParameters['places'] ?? '') ?? 1).clamp(1, 8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.myTrips,
                builder: (context, state) => const MyTripsScreen(),
                routes: [
                  GoRoute(
                    path: Routes.bookingSegment,
                    parentNavigatorKey: _rootNavigatorKey,
                    redirect: (context, state) =>
                        int.tryParse(state.pathParameters['id'] ?? '') == null ? Routes.myTrips : null,
                    builder: (context, state) => BookingScreen(bookingId: int.parse(state.pathParameters['id']!)),
                  ),
                  GoRoute(
                    path: Routes.driverTripSegment,
                    parentNavigatorKey: _rootNavigatorKey,
                    redirect: (context, state) =>
                        int.tryParse(state.pathParameters['id'] ?? '') == null ? Routes.myTrips : null,
                    builder: (context, state) => DriverTripScreen(tripId: int.parse(state.pathParameters['id']!)),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.profile,
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: Routes.kycSegment,
                    parentNavigatorKey: _rootNavigatorKey,
                    redirect: (context, state) =>
                        KycType.fromApi(state.pathParameters['type']) == null ? Routes.profile : null,
                    builder: (context, state) => KycScreen(type: KycType.fromApi(state.pathParameters['type'])!),
                    routes: [
                      GoRoute(
                        path: Routes.kycSubmittedSegment,
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) =>
                            KycSubmittedScreen(type: KycType.fromApi(state.pathParameters['type'])!),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: Routes.vehicleSegment,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const VehicleFormScreen(),
                  ),
                  GoRoute(
                    path: Routes.becomeDriverSegment,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const BecomeDriverScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(path: Routes.notifications, builder: (context, state) => const NotificationsScreen()),
      GoRoute(
        path: Routes.reportPattern,
        redirect: (context, state) => int.tryParse(state.pathParameters['id'] ?? '') == null ? Routes.home : null,
        builder: (context, state) => ReportScreen(
          bookingId: int.parse(state.pathParameters['id']!),
          otherName: state.uri.queryParameters['nom'] ?? 'votre trajet',
        ),
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
