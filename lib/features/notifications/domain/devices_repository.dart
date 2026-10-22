/// Appareils enregistrés pour le push (FCM). Les notifications elles-mêmes sont envoyées par le
/// backend (push, et email de secours) : l'application ne stocke pas de liste de notifications.
abstract interface class DevicesRepository {
  Future<void> registerDevice({required String token, required String platform});

  Future<void> unregisterDevice(String token);
}
