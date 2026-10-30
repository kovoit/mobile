import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/clock.dart';
import '../../domain/entities/otp_challenge.dart';
import 'auth_providers.dart';
import 'code_countdown.dart';

/// « Mot de passe oublié » (écran 4 bis) : étape 1 sans e-mail, étape 2 une fois le code demandé.
/// Le nouveau mot de passe n'est jamais gardé ici (seulement dans le champ de l'écran).
class PasswordResetState {
  const PasswordResetState({this.email, this.countdown = const CodeCountdown(), this.isSending = false, this.error});

  /// `null` : étape 1 (saisie de l'e-mail).
  final String? email;
  final CodeCountdown countdown;
  final bool isSending;

  /// Erreur du dernier renvoi (texte de l'API).
  final String? error;

  bool get codeRequested => email != null;

  Duration remaining(DateTime now) => countdown.remaining(now);

  PasswordResetState copyWith({bool? isSending, String? error, bool clearError = false}) => PasswordResetState(
        email: email,
        countdown: countdown,
        isSending: isSending ?? this.isSending,
        error: clearError ? null : error ?? this.error,
      );
}

class PasswordResetController extends Notifier<PasswordResetState> {
  @override
  PasswordResetState build() => const PasswordResetState();

  DateTime _now() => ref.read(clockProvider)();

  PasswordResetState _sent(OtpChallenge challenge) => PasswordResetState(
        email: challenge.email,
        countdown: CodeCountdown(sentAt: _now(), resendIn: challenge.resendIn),
      );

  /// Étape 1 : l'erreur (429…) est levée pour être affichée sous le champ.
  Future<void> request(String email) async {
    state = _sent(await ref.read(authRepositoryProvider).requestPasswordReset(email));
  }

  /// Renvoi depuis l'étape 2 : l'erreur est gardée dans l'état.
  Future<void> resend() async {
    final email = state.email;
    if (email == null || state.isSending) return;
    state = state.copyWith(isSending: true, clearError: true);
    try {
      state = _sent(await ref.read(authRepositoryProvider).requestPasswordReset(email));
    } on ApiException catch (e) {
      state = state.copyWith(isSending: false, error: e.message);
    }
  }

  /// Étape 2 : l'erreur (`MOT_DE_PASSE_FAIBLE`, `CODE_OTP_INVALIDE`) est levée pour l'écran.
  /// Succès : l'écran renvoie à la Connexion ; le provider (`autoDispose`) est libéré avec l'écran,
  /// l'adresse ne reste pas en mémoire.
  Future<void> reset({required String code, required String password}) async {
    final email = state.email;
    if (email == null) return;
    await ref.read(authRepositoryProvider).resetPassword(email: email, code: code, password: password);
  }

  /// Ouverture de l'écran ou « Modifier mon e-mail » : retour à l'étape 1.
  void restart() => state = const PasswordResetState();
}

/// `autoDispose` : l'état (adresse comprise) disparaît quand l'écran Mot de passe oublié est fermé.
final passwordResetControllerProvider =
    NotifierProvider.autoDispose<PasswordResetController, PasswordResetState>(PasswordResetController.new);
