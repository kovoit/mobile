import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';
import '../utils/app_logger.dart';

/// Données utiles d'un push (`data` FCM) : `notification_id`, `type`, `reservation_id` | `trajet_id`.
typedef PushData = Map<String, String>;

/// Notifications push. Derrière une interface : FCM en production, rien en dev / test.
abstract interface class PushService {
  /// Démarre l'écoute. [onToken] reçoit le jeton à enregistrer côté serveur (et ses renouvellements),
  /// [onMessage] les push reçus app ouverte, [onOpened] ceux touchés par l'utilisateur.
  Future<void> start({
    required void Function(String token, String platform) onToken,
    required void Function(PushData data) onMessage,
    required void Function(PushData data) onOpened,
  });

  /// Jeton courant (pour le désenregistrer à la déconnexion), `null` si indisponible.
  Future<String?> currentToken();

  Future<void> stop();
}

/// Aucun push : l'app relit `/notifications/` périodiquement.
class NoopPushService implements PushService {
  @override
  Future<void> start({
    required void Function(String token, String platform) onToken,
    required void Function(PushData data) onMessage,
    required void Function(PushData data) onOpened,
  }) async {}

  @override
  Future<String?> currentToken() async => null;

  @override
  Future<void> stop() async {}
}

/// Firebase Cloud Messaging. Exige `google-services.json` (Android) et `GoogleService-Info.plist` (iOS).
class FcmPushService implements PushService {
  final List<StreamSubscription<Object?>> _subscriptions = [];
  bool _initialized = false;

  String get _platform => Platform.isIOS ? 'ios' : 'android';

  static PushData _data(RemoteMessage message) =>
      {for (final entry in message.data.entries) entry.key: '${entry.value}'};

  @override
  Future<void> start({
    required void Function(String token, String platform) onToken,
    required void Function(PushData data) onMessage,
    required void Function(PushData data) onOpened,
  }) async {
    try {
      if (!_initialized) {
        await Firebase.initializeApp();
        _initialized = true;
      }
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      final token = await messaging.getToken();
      if (token != null) onToken(token, _platform);
      _subscriptions
        ..add(messaging.onTokenRefresh.listen((t) => onToken(t, _platform)))
        ..add(FirebaseMessaging.onMessage.listen((m) => onMessage(_data(m))))
        ..add(FirebaseMessaging.onMessageOpenedApp.listen((m) => onOpened(_data(m))));

      final initial = await messaging.getInitialMessage();
      if (initial != null) onOpened(_data(initial));
    } on Object catch (e) {
      // Firebase non configuré : on continue sans push (relecture périodique).
      appLogger.w('Push indisponible : $e');
    }
  }

  @override
  Future<String?> currentToken() async => _initialized ? FirebaseMessaging.instance.getToken() : null;

  @override
  Future<void> stop() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
    _subscriptions.clear();
  }
}

final pushServiceProvider = Provider<PushService>((ref) => Env.pushEnabled ? FcmPushService() : NoopPushService());
