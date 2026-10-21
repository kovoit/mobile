import 'package:json_annotation/json_annotation.dart';

import '../domain/app_notification.dart';

part 'notification_dto.g.dart';

/// Objet `notification` (docs/api/after_trip.md).
@JsonSerializable(fieldRename: FieldRename.snake)
class NotificationDto {
  const NotificationDto({
    required this.id,
    required this.type,
    required this.titre,
    required this.message,
    required this.creeLe,
    this.lue = false,
    this.cible = const {},
  });

  factory NotificationDto.fromJson(Map<String, dynamic> json) => _$NotificationDtoFromJson(json);

  final int id;
  final String type;
  final String titre;
  final String message;
  final DateTime creeLe;
  final bool lue;

  /// `{reservation_id}` ou `{trajet_id}`.
  final Map<String, int> cible;

  Map<String, dynamic> toJson() => _$NotificationDtoToJson(this);

  AppNotification toEntity() => AppNotification(
        id: id,
        type: type,
        title: titre,
        message: message,
        createdAt: creeLe,
        read: lue,
        bookingId: cible['reservation_id'],
        tripId: cible['trajet_id'],
      );
}
