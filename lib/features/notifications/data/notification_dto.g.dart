// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationDto _$NotificationDtoFromJson(Map<String, dynamic> json) =>
    NotificationDto(
      id: (json['id'] as num).toInt(),
      type: json['type'] as String,
      titre: json['titre'] as String,
      message: json['message'] as String,
      creeLe: DateTime.parse(json['cree_le'] as String),
      lue: json['lue'] as bool? ?? false,
      cible:
          (json['cible'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const {},
    );

Map<String, dynamic> _$NotificationDtoToJson(NotificationDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'titre': instance.titre,
      'message': instance.message,
      'cree_le': instance.creeLe.toIso8601String(),
      'lue': instance.lue,
      'cible': instance.cible,
    };
