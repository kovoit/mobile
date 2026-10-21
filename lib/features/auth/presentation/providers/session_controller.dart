import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_providers.dart';

/// Session courante : `null` = déconnecté. Le routeur s'appuie dessus pour les redirections.
///
/// Les actions (verifyCode, completeProfile…) ne passent PAS l'état en chargement/erreur :
/// les écrans gèrent leur propre indicateur et affichent l'erreur levée.
/// L'état ne change qu'en cas de succès, ce qui évite de renvoyer vers le Splash.
class SessionController extends AsyncNotifier<AppUser?> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  Future<AppUser?> build() async {
    ref.listen(sessionExpiredProvider, (_, _) => state = const AsyncData(null));
    final results = await Future.wait<Object?>([
      ref.read(authRepositoryProvider).restoreSession(),
      Future<void>.delayed(ref.read(splashMinDurationProvider)),
    ]);
    return results.first as AppUser?;
  }

  /// Relance la restauration (bouton « Réessayer » du Splash).
  void retry() => ref.invalidateSelf();

  /// Ouvre la session avec le code reçu par e-mail (compte créé s'il n'existait pas).
  Future<void> verifyCode({required String email, required String code}) async {
    state = AsyncData(await _repository.verifyCode(email: email, code: code));
  }

  Future<void> completeProfile({required String prenom, required String nom, required String telephone}) async {
    state = AsyncData(await _repository.completeProfile(prenom: prenom, nom: nom, telephone: telephone));
  }

  /// À appeler après une action qui modifie les statuts (KYC envoyé, véhicule déclaré).
  Future<void> refreshUser() async {
    state = AsyncData(await _repository.refreshUser());
  }

  /// Bascule de mode. Les droits sont vérifiés avant l'appel (AccessPolicy) et par le backend.
  Future<void> switchMode(UserMode mode) async {
    state = AsyncData(await _repository.updateMode(mode));
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AsyncData(null);
  }
}

final sessionControllerProvider = AsyncNotifierProvider<SessionController, AppUser?>(SessionController.new);
