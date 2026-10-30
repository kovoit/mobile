import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/clock.dart';
import '../../domain/entities/otp_challenge.dart';
import '../../domain/entities/registration.dart';
import 'auth_providers.dart';
import 'code_countdown.dart';

/// D'où vient l'écran Vérification : « Modifier mon e-mail » revient à l'inscription (D-75).
enum VerificationOrigin { registration, login }

/// Adresse à vérifier et délai de renvoi. Aucun mot de passe n'est gardé ici.
class EmailVerificationState {
  const EmailVerificationState({
    this.email,
    this.origin = VerificationOrigin.registration,
    this.countdown = const CodeCountdown(),
    this.isSending = false,
    this.error,
  });

  /// `null` : aucune vérification en cours (l'écran renvoie à la Connexion).
  final String? email;
  final VerificationOrigin origin;
  final CodeCountdown countdown;
  final bool isSending;

  /// Erreur du dernier renvoi (texte de l'API).
  final String? error;

  Duration remaining(DateTime now) => countdown.remaining(now);

  EmailVerificationState copyWith({bool? isSending, String? error, bool clearError = false}) => EmailVerificationState(
        email: email,
        origin: origin,
        countdown: countdown,
        isSending: isSending ?? this.isSending,
        error: clearError ? null : error ?? this.error,
      );
}

/// Inscription puis vérification de l'e-mail, ou connexion d'une adresse non vérifiée
/// (403 `EMAIL_NON_VERIFIE`). Survit à la navigation Inscription ↔ Vérification.
class EmailVerificationController extends Notifier<EmailVerificationState> {
  @override
  EmailVerificationState build() => const EmailVerificationState();

  DateTime _now() => ref.read(clockProvider)();

  EmailVerificationState _sent(OtpChallenge challenge, VerificationOrigin origin) => EmailVerificationState(
        email: challenge.email,
        origin: origin,
        countdown: CodeCountdown(sentAt: _now(), resendIn: challenge.resendIn),
      );

  /// Crée le compte (le code part par e-mail). L'erreur est levée pour l'écran Inscription.
  Future<void> register(Registration registration) async {
    final challenge = await ref.read(authRepositoryProvider).register(registration);
    state = _sent(challenge, VerificationOrigin.registration);
  }

  /// Connexion refusée par 403 `EMAIL_NON_VERIFIE` : le serveur vient d'envoyer un code (ou
  /// attend la fin du délai), sans dire lequel. Compte à rebours par défaut, puis « Renvoyer ».
  void startFromLogin(String email) => state = _sent(
        OtpChallenge(email: email.trim().toLowerCase(), resendIn: OtpChallenge.defaultResendIn),
        VerificationOrigin.login,
      );

  /// Renvoi depuis l'écran Vérification : l'erreur (429…) est gardée dans l'état.
  Future<void> resend() async {
    final email = state.email;
    if (email == null || state.isSending) return;
    state = state.copyWith(isSending: true, clearError: true);
    try {
      final challenge = await ref.read(authRepositoryProvider).resendVerificationCode(email);
      state = _sent(challenge, state.origin);
    } on ApiException catch (e) {
      state = state.copyWith(isSending: false, error: e.message);
    }
  }

  void reset() => state = const EmailVerificationState();
}

final emailVerificationControllerProvider =
    NotifierProvider<EmailVerificationController, EmailVerificationState>(EmailVerificationController.new);
