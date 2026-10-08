import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/otp_challenge.dart';

part 'otp_challenge_dto.g.dart';

/// Réponse de `/auth/otp/send/` : délais en secondes.
@JsonSerializable(fieldRename: FieldRename.snake)
class OtpChallengeDto {
  const OtpChallengeDto({required this.telephone, this.expireDans = 300, this.renvoiDans = 30});

  factory OtpChallengeDto.fromJson(Map<String, dynamic> json) => _$OtpChallengeDtoFromJson(json);

  final String telephone;
  final int expireDans;
  final int renvoiDans;

  Map<String, dynamic> toJson() => _$OtpChallengeDtoToJson(this);

  OtpChallenge toEntity() => OtpChallenge(
        telephone: telephone,
        resendIn: Duration(seconds: renvoiDans),
        expiresIn: Duration(seconds: expireDans),
      );
}
