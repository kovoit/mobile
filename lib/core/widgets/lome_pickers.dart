import 'package:flutter/material.dart';

/// Sélecteurs de date et d'heure en heure de Lomé (UTC). Les dates reçues et renvoyées sont des
/// heures « murales » : on ne passe jamais par le fuseau du téléphone.
abstract final class LomePickers {
  /// Date du jour à J+[maxDays]. Renvoie une date sans heure, ou `null` si annulé.
  static Future<DateTime?> pickDate(
    BuildContext context, {
    required DateTime now,
    required DateTime current,
    String helpText = 'Date du trajet',
    int maxDays = 30,
  }) {
    final utcNow = now.toUtc();
    final today = DateTime(utcNow.year, utcNow.month, utcNow.day);
    final currentDay = DateTime(current.year, current.month, current.day);
    return showDatePicker(
      context: context,
      initialDate: currentDay.isBefore(today) ? today : currentDay,
      firstDate: today,
      lastDate: today.add(Duration(days: maxDays)),
      helpText: helpText,
    );
  }

  /// Heure au format 24 h. Renvoie `null` si annulé.
  static Future<TimeOfDay?> pickTime(BuildContext context, {required DateTime current, String helpText = 'Heure'}) =>
      showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
        helpText: helpText,
        builder: (context, child) =>
            MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: child!),
      );
}
