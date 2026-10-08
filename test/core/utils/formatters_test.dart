import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kovoit/core/utils/formatters.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr'));

  group('Formatters.fcfa', () {
    test('formate un petit montant', () {
      expect(Formatters.fcfa(300), '300 FCFA');
    });

    test('sépare les milliers à la française', () {
      // intl utilise une espace insécable étroite comme séparateur.
      expect(Formatters.fcfa(18500).replaceAll(RegExp(r'\s'), ' '), '18 500 FCFA');
    });
  });

  group('Formatters dates (heure de Lomé = UTC)', () {
    final departure = DateTime.utc(2026, 10, 8, 7, 30);

    test('date courte', () => expect(Formatters.date(departure), '08 oct. 2026'));
    test('heure', () => expect(Formatters.time(departure), '07:30'));
    test('date longue avec majuscule', () => expect(Formatters.longDate(departure), 'Jeudi 08 octobre'));
  });

  test('distanceKm', () {
    expect(Formatters.distanceKm(1.2), '1.2 km');
    expect(Formatters.distanceKm(0.85), '850 m');
  });

  test('placesRemaining gère le singulier', () {
    expect(Formatters.placesRemaining(1), '1 place restante');
    expect(Formatters.placesRemaining(3), '3 places restantes');
  });

  test('phone formate un numéro togolais', () {
    expect(Formatters.phone('+22890123456'), '+228 90 12 34 56');
    expect(Formatters.phone('90123456'), '+228 90 12 34 56');
  });
}
