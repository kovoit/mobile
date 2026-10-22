import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/booking/presentation/providers/booking_providers.dart';
import 'features/driver/presentation/providers/driver_providers.dart';
import 'features/notifications/presentation/push_coordinator.dart';

class KovoitApp extends ConsumerStatefulWidget {
  const KovoitApp({super.key});

  @override
  ConsumerState<KovoitApp> createState() => _KovoitAppState();
}

class _KovoitAppState extends ConsumerState<KovoitApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Retour au premier plan : on relit les statuts qui ont pu changer pendant l'absence.
    _lifecycle = AppLifecycleListener(
      onResume: () {
        ref.read(myBookingsProvider.notifier).refresh();
        ref.read(myDriverTripsProvider.notifier).refresh();
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(pushCoordinatorProvider);
    return MaterialApp.router(
      title: 'Kovoit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: ref.watch(appRouterProvider),
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
