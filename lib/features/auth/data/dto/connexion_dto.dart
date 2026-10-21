import 'package:json_annotation/json_annotation.dart';

import 'profil_dto.dart';

part 'connexion_dto.g.dart';

/// Réponse de `POST /auth/otp/verifier/`.
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class ConnexionDto {
  const ConnexionDto({
    required this.utilisateur,
    required this.access,
    required this.refresh,
    this.nouveauCompte = false,
  });

  factory ConnexionDto.fromJson(Map<String, dynamic> json) => _$ConnexionDtoFromJson(json);

  final ProfilDto utilisateur;
  final String access;
  final String refresh;
  final bool nouveauCompte;
}
