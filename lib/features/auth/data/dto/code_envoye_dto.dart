import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/otp_challenge.dart';

part 'code_envoye_dto.g.dart';

/// `CODE_ENVOYE` : réponse de `auth/inscription/`, `auth/inscription/renvoyer-code/` et
/// `auth/mot-de-passe/oublie/`. `delai_renvoi_s` = paramètre `otp_delai_renvoi_s`.
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class CodeEnvoyeDto {
  const CodeEnvoyeDto({required this.email, this.delaiRenvoiS = 60});

  factory CodeEnvoyeDto.fromJson(Map<String, dynamic> json) => _$CodeEnvoyeDtoFromJson(json);

  final String email;
  final int delaiRenvoiS;

  OtpChallenge toEntity() => OtpChallenge(email: email, resendIn: Duration(seconds: delaiRenvoiS));
}
