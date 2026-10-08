import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/domain/entities/app_user.dart';
import 'routes.dart';

/// Redirection selon l'état de session (claude.md §3).
/// Fonction pure pour être testée sans widget. Retourne `null` si la route est autorisée.
///
/// 1. Session en cours de restauration ou en erreur → Splash (qui affiche « Réessayer »).
/// 2. Déconnecté → connexion / inscription / mot de passe oublié uniquement.
/// 3. Connecté sans numéro → saisie du numéro ; numéro non vérifié → code SMS.
/// 4. Téléphone vérifié → l'application ; les écrans d'auth renvoient vers « Rechercher ».
///
/// Les droits KYC (réserver, publier) sont vérifiés au moment de l'action (Sprint S2+),
/// pas par une redirection globale : la recherche reste ouverte dès l'OTP validé.
String? authRedirect(AsyncValue<AppUser?> session, String location) {
  if (session.isLoading || session.hasError) {
    return location == Routes.splash ? null : Routes.splash;
  }

  final user = session.value;
  if (user == null) {
    return Routes.publicAuth.contains(location) ? null : Routes.login;
  }

  if (!user.hasTelephone) {
    return location == Routes.phone ? null : Routes.phone;
  }

  if (!user.telephoneVerifie) {
    return Routes.phoneVerification.contains(location) ? null : Routes.otp;
  }

  final onEntryScreen = location == Routes.splash ||
      Routes.publicAuth.contains(location) ||
      Routes.phoneVerification.contains(location);
  return onEntryScreen ? Routes.search : null;
}
