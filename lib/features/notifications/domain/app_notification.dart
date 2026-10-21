/// Notification d'un changement de statut (spéc. : « chaque changement de statut envoie une notification »).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.read,
    this.bookingId,
    this.tripId,
  });

  final int id;

  /// Ex. `reservation_acceptee`, `nouvelle_demande`, `trajet_termine`.
  final String type;
  final String title;

  /// Ne contient jamais le code de départ (affichage possible sur l'écran verrouillé).
  final String message;
  final DateTime createdAt;
  final bool read;

  /// Cible : réservation du passager, ou trajet publié du conducteur.
  final int? bookingId;
  final int? tripId;

  bool get concernsKyc => type.startsWith('kyc_');
}

abstract interface class NotificationsRepository {
  Future<List<AppNotification>> list();

  /// Marque comme lues [ids], ou toutes si `null`.
  Future<void> markRead([List<int>? ids]);

  /// Enregistre l'appareil pour le push (token FCM).
  Future<void> registerDevice({required String token, required String platform});

  Future<void> unregisterDevice(String token);
}
