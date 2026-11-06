import 'dart:async';

import 'package:kovoit/core/config/env.dart';

/// Chargé automatiquement par `flutter test` avant chaque fichier de test : les tests tournent
/// sur la fausse API en mémoire (FakeBackend), alors que l'app vise le vrai backend par défaut.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  Env.debugUseMockApiOverride = true;
  await testMain();
}
