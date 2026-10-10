/// Heures « murales » de Lomé, représentées en UTC (Lomé = UTC+0 toute l'année),
/// quel que soit le fuseau réglé sur le téléphone (claude.md §5).
abstract final class LomeTime {
  /// Prochain quart d'heure : heure proposée par défaut dans les formulaires (recherche, publication).
  static DateTime nextQuarterHour(DateTime now) {
    final utc = now.toUtc();
    final base = DateTime.utc(utc.year, utc.month, utc.day, utc.hour);
    return base.add(Duration(minutes: ((utc.minute ~/ 15) + 1) * 15));
  }

  /// Remplace la date en gardant l'heure.
  static DateTime withDate(DateTime current, DateTime date) =>
      DateTime.utc(date.year, date.month, date.day, current.hour, current.minute);

  /// Remplace l'heure en gardant la date.
  static DateTime withTime(DateTime current, int hour, int minute) =>
      DateTime.utc(current.year, current.month, current.day, hour, minute);
}
