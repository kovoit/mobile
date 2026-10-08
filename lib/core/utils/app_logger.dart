import 'package:logger/logger.dart';

import '../config/env.dart';

/// Logger de l'application (à utiliser à la place de `print`).
/// Ne jamais y écrire de code de départ, de token ni de donnée KYC.
final Logger appLogger = Logger(
  level: Env.isDev ? Level.debug : Level.warning,
  printer: PrettyPrinter(methodCount: 0, noBoxingByDefault: true),
);
