import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/access_policy.dart';
import '../../../auth/presentation/providers/session_controller.dart';
import '../../../kyc/presentation/widgets/access_required_card.dart';
import '../../../search/presentation/screens/search_screen.dart';
import 'placeholder_screen.dart';

/// Tableau de bord du premier onglet, selon le mode actif :
/// - passager → « Rechercher un trajet » ;
/// - conducteur → « Espace Conducteur » (S5).
/// Tant que les droits manquent, une carte explique la restriction (retour UX du 08/10) :
/// la consultation reste ouverte, seules réservation / publication sont bloquées.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionControllerProvider).value;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    if (user.isDriverMode) {
      final denial = AccessPolicy.canPublish(user);
      return PlaceholderScreen(
        title: 'Espace Conducteur',
        subtitle: 'Partagez votre route. Allégez vos dépenses.',
        sprint: 'S5',
        notice: denial == null ? null : AccessRequiredCard(denial: denial, suspendedUntil: user.suspenduJusquAu),
      );
    }

    // La carte « accès restreint » est affichée par l'écran de recherche lui-même.
    return const SearchScreen();
  }
}
