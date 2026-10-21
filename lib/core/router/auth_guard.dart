import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/domain/entities/app_user.dart';
import 'routes.dart';

/// Redirection selon l'état de session (claude.md §3).
/// Fonction pure pour être testée sans widget. Retourne `null` si la route est autorisée.
///
/// 1. Session en cours de restauration ou en erreur → Splash (qui affiche « Réessayer »).
/// 2. Déconnecté → saisie de l'e-mail et du code uniquement.
/// 3. Connecté, profil incomplet (prénom, nom, téléphone) → complétion du profil.
/// 4. Profil complet → l'application ; les écrans d'entrée renvoient vers l'accueil.
///
/// Le KYC ne bloque PAS la navigation (retour UX du 08/10) : il se fait depuis le Profil.
/// Réserver, publier et passer en mode conducteur sont contrôlés au moment de l'action
/// par `AccessPolicy` (et par le backend).
String? authRedirect(AsyncValue<AppUser?> session, String location) {
  if (session.isLoading || session.hasError) {
    return location == Routes.splash ? null : Routes.splash;
  }

  final user = session.value;
  if (user == null) {
    return Routes.publicAuth.contains(location) ? null : Routes.login;
  }

  if (!user.profilComplet) {
    return location == Routes.completeProfile ? null : Routes.completeProfile;
  }

  final onEntryScreen =
      location == Routes.splash || Routes.publicAuth.contains(location) || location == Routes.completeProfile;
  return onEntryScreen ? Routes.home : null;
}
