import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

/// Capture tout ce qui passe par le journal de l'app (`appLogger`, quel que soit le niveau filtré)
/// le temps d'un test. Sert à vérifier qu'aucun secret n'y est écrit (CA0, R-02).
class LogCapture {
  LogCapture._();

  final List<String> lines = [];

  /// À appeler au début du test : l'écouteur est retiré à la fin (`addTearDown`).
  static LogCapture start() {
    final capture = LogCapture._();
    void onLog(LogEvent event) => capture.lines.add('${event.message} ${event.error ?? ''}');
    Logger.addLogListener(onLog);
    addTearDown(() => Logger.removeLogListener(onLog));
    return capture;
  }

  /// Vrai si une ligne du journal contient [secret].
  bool mentions(String secret) => lines.any((line) => line.contains(secret));
}
