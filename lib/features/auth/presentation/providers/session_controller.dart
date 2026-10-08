import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_providers.dart';

/// Session courante : `null` = déconnecté. Le routeur s'appuie dessus pour les redirections.
///
/// Les actions (login, register…) ne passent PAS l'état en chargement/erreur :
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

  Future<void> login({required String email, required String password}) async {
    state = AsyncData(await _repository.login(email: email, password: password));
  }

  Future<void> register({
    required String nomComplet,
    required String email,
    required String telephone,
    required String password,
  }) async {
    state = AsyncData(
      await _repository.register(nomComplet: nomComplet, email: email, telephone: telephone, password: password),
    );
  }

  /// Retourne `false` si l'utilisateur a annulé la fenêtre Google.
  Future<bool> signInWithGoogle() async {
    final user = await _repository.signInWithGoogle();
    if (user == null) return false;
    state = AsyncData(user);
    return true;
  }

  Future<void> updatePhone(String telephone) async {
    state = AsyncData(await _repository.updatePhone(telephone));
  }

  Future<void> verifyOtp(String code) async {
    state = AsyncData(await _repository.verifyOtp(code));
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AsyncData(null);
  }
}

final sessionControllerProvider = AsyncNotifierProvider<SessionController, AppUser?>(SessionController.new);
