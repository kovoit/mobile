/// Notification conservée par le backend (écran « Notifications ») : aussi visible quand le
/// push n'est jamais arrivé (téléphone éteint, push non configuré).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.titre,
    required this.message,
    required this.donnees,
    required this.creeLe,
    this.lueLe,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as String,
        titre: json['titre'] as String,
        message: json['message'] as String,
        donnees: {
          for (final e in ((json['donnees'] as Map?) ?? const {}).entries) '${e.key}': '${e.value}',
        },
        creeLe: DateTime.parse(json['cree_le'] as String),
        lueLe: json['lue_le'] == null ? null : DateTime.parse(json['lue_le'] as String),
      );

  final String id;
  final String titre;
  final String message;

  /// Écran à ouvrir (mêmes clés que le push) : reservation_id, trajet_id, destinataire.
  final Map<String, String> donnees;
  final DateTime creeLe;
  final DateTime? lueLe;

  bool get lue => lueLe != null;
}
