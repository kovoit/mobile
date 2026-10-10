import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/session_controller.dart';
import '../../../driver/presentation/screens/driver_space_screen.dart';
import '../../../search/presentation/screens/search_screen.dart';

/// Tableau de bord du premier onglet, selon le mode actif :
/// - passager → « Rechercher un trajet » ;
/// - conducteur → « Espace Conducteur ».
/// Chaque écran affiche lui-même la carte « accès restreint » quand les droits manquent
/// (retour UX du 08/10) : la consultation reste ouverte, seules réservation / publication sont bloquées.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionControllerProvider).value;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return user.isDriverMode ? const DriverSpaceScreen() : const SearchScreen();
  }
}
