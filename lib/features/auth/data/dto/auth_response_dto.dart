import 'package:json_annotation/json_annotation.dart';

import 'user_dto.dart';

part 'auth_response_dto.g.dart';

/// Réponse de `/auth/register/`, `/auth/login/` et `/auth/google/`.
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class AuthResponseDto {
  const AuthResponseDto({required this.access, required this.refresh, required this.user});

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) => _$AuthResponseDtoFromJson(json);

  final String access;
  final String refresh;
  final UserDto user;

  Map<String, dynamic> toJson() => _$AuthResponseDtoToJson(this);
}
