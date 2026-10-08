import 'package:flutter_test/flutter_test.dart';
import 'package:kovoit/core/utils/validators.dart';

void main() {
  group('Validators.normalizeTogoPhone', () {
    test('accepte les formats courants', () {
      expect(Validators.normalizeTogoPhone('90 12 34 56'), '+22890123456');
      expect(Validators.normalizeTogoPhone('+228 70 12 34 56'), '+22870123456');
      expect(Validators.normalizeTogoPhone('0022899123456'), '+22899123456');
    });

    test('rejette les numéros invalides', () {
      expect(Validators.normalizeTogoPhone('80123456'), isNull); // ne commence pas par 7 ou 9
      expect(Validators.normalizeTogoPhone('9012345'), isNull); // trop court
      expect(Validators.normalizeTogoPhone('+229 90 12 34 56'), isNull); // autre pays
    });
  });

  test('togoPhone renvoie un message', () {
    expect(Validators.togoPhone(''), isNotNull);
    expect(Validators.togoPhone('123'), isNotNull);
    expect(Validators.togoPhone('90123456'), isNull);
  });

  test('email', () {
    expect(Validators.email('kodjo@exemple.com'), isNull);
    expect(Validators.email('kodjo@'), isNotNull);
  });

  test('password exige 8 caractères', () {
    expect(Validators.password('1234567'), isNotNull);
    expect(Validators.password('12345678'), isNull);
  });

  test('numericCode distingue OTP (6) et code de départ (4)', () {
    expect(Validators.numericCode('731906', length: 6), isNull);
    expect(Validators.numericCode('4821', length: 4), isNull);
    expect(Validators.numericCode('4821', length: 6), isNotNull);
    expect(Validators.numericCode('48a1', length: 4), isNotNull);
  });
}
