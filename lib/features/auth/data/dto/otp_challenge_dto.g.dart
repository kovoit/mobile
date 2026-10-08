// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'otp_challenge_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OtpChallengeDto _$OtpChallengeDtoFromJson(Map<String, dynamic> json) =>
    OtpChallengeDto(
      telephone: json['telephone'] as String,
      expireDans: (json['expire_dans'] as num?)?.toInt() ?? 300,
      renvoiDans: (json['renvoi_dans'] as num?)?.toInt() ?? 30,
    );

Map<String, dynamic> _$OtpChallengeDtoToJson(OtpChallengeDto instance) =>
    <String, dynamic>{
      'telephone': instance.telephone,
      'expire_dans': instance.expireDans,
      'renvoi_dans': instance.renvoiDans,
    };
