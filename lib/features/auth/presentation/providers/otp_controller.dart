import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/clock.dart';
import 'auth_providers.dart';

class OtpState {
  const OtpState({this.email, this.sentAt, this.resendIn = Duration.zero, this.isSending = false, this.error});

  /// Adresse à laquelle le dernier code a été envoyé. `null` : aucun code demandé.
  final String? email;
  final DateTime? sentAt;
  final Duration resendIn;
  final bool isSending;
  final String? error;

  /// Temps restant avant de pouvoir redemander un code.
  Duration remaining(DateTime now) {
    if (sentAt == null) return Duration.zero;
    final left = sentAt!.add(resendIn).difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  OtpState copyWith({bool? isSending, String? error, bool clearError = false}) => OtpState(
        email: email,
        sentAt: sentAt,
        resendIn: resendIn,
        isSending: isSending ?? this.isSending,
        error: clearError ? null : error ?? this.error,
      );
}

/// Envoi du code de connexion par e-mail et délai de renvoi.
/// Survit à la navigation entre l'écran e-mail et l'écran du code.
class OtpController extends Notifier<OtpState> {
  @override
  OtpState build() => const OtpState();

  DateTime now() => ref.read(clockProvider)();

  /// Premier envoi depuis l'écran e-mail : l'erreur est levée pour y être affichée.
  /// Si un code vient d'être envoyé à la même adresse, aucun nouvel envoi n'est fait.
  Future<void> request(String email) async {
    final normalized = email.trim().toLowerCase();
    if (state.email == normalized && state.remaining(now()) > Duration.zero) return;
    state = state.copyWith(isSending: true, clearError: true);
    try {
      final challenge = await ref.read(authRepositoryProvider).requestCode(normalized);
      state = OtpState(email: challenge.email, sentAt: now(), resendIn: challenge.resendIn);
    } on ApiException {
      state = state.copyWith(isSending: false);
      rethrow;
    }
  }

  /// Renvoi depuis l'écran du code : l'erreur est gardée dans l'état.
  Future<void> resend() async {
    final email = state.email;
    if (email == null || state.isSending) return;
    state = state.copyWith(isSending: true, clearError: true);
    try {
      final challenge = await ref.read(authRepositoryProvider).requestCode(email);
      state = OtpState(email: challenge.email, sentAt: now(), resendIn: challenge.resendIn);
    } on ApiException catch (e) {
      state = state.copyWith(isSending: false, error: e.message);
    }
  }

  void reset() => state = const OtpState();
}

final otpControllerProvider = NotifierProvider<OtpController, OtpState>(OtpController.new);
