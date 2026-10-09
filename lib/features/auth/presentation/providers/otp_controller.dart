import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/clock.dart';
import 'auth_providers.dart';

class OtpState {
  const OtpState({this.telephone, this.sentAt, this.resendIn = Duration.zero, this.isSending = false, this.error});

  final String? telephone;
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

  OtpState copyWith({
    String? telephone,
    DateTime? sentAt,
    Duration? resendIn,
    bool? isSending,
    String? error,
    bool clearError = false,
  }) =>
      OtpState(
        telephone: telephone ?? this.telephone,
        sentAt: sentAt ?? this.sentAt,
        resendIn: resendIn ?? this.resendIn,
        isSending: isSending ?? this.isSending,
        error: clearError ? null : error ?? this.error,
      );
}

/// Envoi du code OTP SMS et délai de renvoi.
/// Survit aux reconstructions de l'écran pour ne pas renvoyer un SMS à chaque visite.
class OtpController extends Notifier<OtpState> {
  @override
  OtpState build() => const OtpState();

  DateTime now() => ref.read(clockProvider)();

  /// Envoie un code si aucun n'a été envoyé pour ce numéro ou si le délai est écoulé.
  Future<void> sendIfNeeded(String telephone) async {
    final alreadySent = state.telephone == telephone && state.remaining(now()) > Duration.zero;
    if (alreadySent || state.isSending) return;
    await send();
  }

  Future<void> send() async {
    if (state.isSending) return;
    state = state.copyWith(isSending: true, clearError: true);
    try {
      final challenge = await ref.read(authRepositoryProvider).sendOtp();
      state = OtpState(telephone: challenge.telephone, sentAt: now(), resendIn: challenge.resendIn);
    } on ApiException catch (e) {
      state = state.copyWith(isSending: false, error: e.message);
    }
  }

  /// Après un changement de numéro, le prochain passage sur l'écran renverra un code.
  void reset() => state = const OtpState();
}

final otpControllerProvider = NotifierProvider<OtpController, OtpState>(OtpController.new);
