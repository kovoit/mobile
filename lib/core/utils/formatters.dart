import 'package:intl/intl.dart';

/// Formats d'affichage. Aucun calcul métier ici : on formate des valeurs venues de l'API.
abstract final class Formatters {
  static final NumberFormat _amount = NumberFormat.decimalPattern('fr');

  /// `300` → `300 FCFA`, `18500` → `18 500 FCFA`.
  static String fcfa(int amount) => '${_amount.format(amount)} FCFA';

  /// Lomé est à UTC+0 toute l'année (pas d'heure d'été) : afficher en heure de Lomé
  /// revient à afficher en UTC, quel que soit le fuseau du téléphone.
  static DateTime toLome(DateTime dateTime) => dateTime.toUtc();

  /// `08 oct. 2026`
  static String date(DateTime dateTime) => DateFormat('dd MMM y', 'fr').format(toLome(dateTime));

  /// `Jeudi 08 octobre`
  static String longDate(DateTime dateTime) {
    final text = DateFormat('EEEE dd MMMM', 'fr').format(toLome(dateTime));
    return text[0].toUpperCase() + text.substring(1);
  }

  /// `07:30`
  static String time(DateTime dateTime) => DateFormat('HH:mm', 'fr').format(toLome(dateTime));

  /// `1.2 km` / `850 m` : affichage d'une distance renvoyée par l'API.
  static String distanceKm(double km) {
    if (km < 1) return '${(km * 1000).round()} m';
    return '${km.toStringAsFixed(1)} km';
  }

  /// `1 place restante` / `3 places restantes`
  static String placesRemaining(int count) => count <= 1 ? '$count place restante' : '$count places restantes';

  /// `+228 90 12 34 56` à partir de `+22890123456` ou `90123456`.
  static String phone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    final local = digits.startsWith('228') && digits.length == 11 ? digits.substring(3) : digits;
    if (local.length != 8) return raw;
    final pairs = [for (var i = 0; i < 8; i += 2) local.substring(i, i + 2)];
    return '+228 ${pairs.join(' ')}';
  }
}
