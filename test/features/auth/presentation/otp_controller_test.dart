import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
    when(() => repository.sendOtp()).thenAnswer(
      (_) async => const OtpChallenge(
        telephone: '+22890123456',
        resendIn: Duration(seconds: 30),
        expiresIn: Duration(minutes: 5),
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

  test('n’envoie pas un second SMS pendant le délai de renvoi', () async {
    await controller().sendIfNeeded('+22890123456');
    now = now.add(const Duration(seconds: 10));
    await controller().sendIfNeeded('+22890123456');

    verify(() => repository.sendOtp()).called(1);
    expect(container.read(otpControllerProvider).remaining(now), const Duration(seconds: 20));
  });

  test('renvoie après le délai', () async {
    await controller().sendIfNeeded('+22890123456');
    now = now.add(const Duration(seconds: 31));
    await controller().sendIfNeeded('+22890123456');

    verify(() => repository.sendOtp()).called(2);
  });

  test('renvoie immédiatement si le numéro a changé', () async {
    await controller().sendIfNeeded('+22890123456');
    await controller().sendIfNeeded('+22891111111');

    verify(() => repository.sendOtp()).called(2);
  });
}
