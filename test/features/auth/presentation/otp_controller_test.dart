import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kovoit/core/network/api_exception.dart';
import 'package:kovoit/core/utils/clock.dart';
import 'package:kovoit/features/auth/domain/entities/otp_challenge.dart';
import 'package:kovoit/features/auth/domain/repositories/auth_repository.dart';
import 'package:kovoit/features/auth/presentation/providers/auth_providers.dart';
import 'package:kovoit/features/auth/presentation/providers/otp_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements AuthRepository {}

void main() {
  late _MockRepository repository;
  late DateTime now;
  late ProviderContainer container;

  setUp(() {
    repository = _MockRepository();
    now = DateTime(2026, 10, 8, 7, 30);
    when(() => repository.requestCode(any())).thenAnswer(
      (invocation) async => OtpChallenge(
        email: (invocation.positionalArguments.first as String).trim().toLowerCase(),
        resendIn: const Duration(seconds: 60),
      ),
    );
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(container.dispose);
  });

  OtpController controller() => container.read(otpControllerProvider.notifier);

  test('n’envoie pas un second e-mail à la même adresse pendant le délai de renvoi', () async {
    await controller().request('afi@exemple.com');
    now = now.add(const Duration(seconds: 10));
    await controller().request(' AFI@exemple.com ');

    verify(() => repository.requestCode(any())).called(1);
    expect(container.read(otpControllerProvider).remaining(now), const Duration(seconds: 50));
  });

  test('envoie immédiatement si l’adresse a changé', () async {
    await controller().request('afi@exemple.com');
    await controller().request('kodjo@exemple.com');

    verify(() => repository.requestCode(any())).called(2);
    expect(container.read(otpControllerProvider).email, 'kodjo@exemple.com');
  });

  test('renvoi : une erreur reste affichée dans l’état', () async {
    await controller().request('afi@exemple.com');
    when(() => repository.requestCode(any()))
        .thenThrow(const TooManyAttemptsApiException('Patientez 60 secondes avant de demander un nouveau code.'));

    await controller().resend();

    final state = container.read(otpControllerProvider);
    expect(state.error, 'Patientez 60 secondes avant de demander un nouveau code.');
    expect(state.isSending, isFalse);
  });

  test('premier envoi : l’erreur est levée pour l’écran e-mail', () async {
    when(() => repository.requestCode(any())).thenThrow(const NetworkApiException());

    await expectLater(controller().request('afi@exemple.com'), throwsA(isA<NetworkApiException>()));
    expect(container.read(otpControllerProvider).email, isNull);
  });
}
