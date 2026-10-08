import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/app_user.dart';

part 'user_dto.g.dart';

/// Objet `user` de l'API (voir docs/api/auth.md).
@JsonSerializable(fieldRename: FieldRename.snake)
class UserDto {
  const UserDto({
    required this.id,
    required this.prenom,
    required this.nom,
    required this.email,
    this.telephone,
    this.telephoneVerifie = false,
    this.photo,
    this.modeActif,
    this.statutCompte,
    this.suspenduJusquAu,
    this.kycPassager,
    this.kycConducteur,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) => _$UserDtoFromJson(json);

  final int id;
  final String prenom;
  final String nom;
  final String email;
  final String? telephone;
  final bool telephoneVerifie;
  final String? photo;
  final String? modeActif;
  final String? statutCompte;
  final DateTime? suspenduJusquAu;
  final String? kycPassager;
  final String? kycConducteur;

  Map<String, dynamic> toJson() => _$UserDtoToJson(this);

  AppUser toEntity() => AppUser(
        id: id,
        prenom: prenom,
        nom: nom,
        email: email,
        telephone: telephone,
        telephoneVerifie: telephoneVerifie,
        photoUrl: photo,
        modeActif: UserMode.fromApi(modeActif),
        statutCompte: AccountStatus.fromApi(statutCompte),
        suspenduJusquAu: suspenduJusquAu,
        kycPassager: KycStatus.fromApi(kycPassager),
        kycConducteur: KycStatus.fromApi(kycConducteur),
      );
}
