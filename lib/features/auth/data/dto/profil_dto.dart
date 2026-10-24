import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/app_user.dart';

part 'profil_dto.g.dart';

/// `ProfilSerializer` du backend (`GET /moi/`, `utilisateur` de `POST /auth/otp/verifier/`).
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class ProfilDto {
  const ProfilDto({
    required this.id,
    required this.email,
    this.telephone = '',
    this.nom = '',
    this.prenom = '',
    this.photo,
    this.emailVerifie = false,
    this.modeActif,
    this.statutCompte,
    this.suspenduJusquAu,
    this.profilComplet = false,
    this.cguAcceptees = true,
    this.cguUrl = 'https://kovoittg.com/conditions-utilisation/',
    this.kyc = const {},
    this.etat = const {},
  });

  factory ProfilDto.fromJson(Map<String, dynamic> json) => _$ProfilDtoFromJson(json);

  final String id;
  final String email;
  final String telephone;
  final String nom;
  final String prenom;
  final String? photo;
  final bool emailVerifie;
  final String? modeActif;
  final String? statutCompte;
  final DateTime? suspenduJusquAu;
  final bool profilComplet;

  /// Faux : l'app demande d'accepter les CGU en vigueur avant tout autre écran.
  final bool cguAcceptees;
  final String cguUrl;

  /// `{"passager": "verifie", "conducteur": "non_verifie"}`
  final Map<String, dynamic> kyc;

  /// `{"badge_kyc", "acces": {...}, "mode_conducteur": {...}, "alertes": [...]}`
  final Map<String, dynamic> etat;

  bool get _vehiculeDeclare {
    final modeConducteur = etat['mode_conducteur'];
    return modeConducteur is Map && modeConducteur['vehicule_declare'] == true;
  }

  AppUser toEntity() => AppUser(
        id: id,
        prenom: prenom,
        nom: nom,
        email: email,
        telephone: telephone.isEmpty ? null : telephone,
        profilComplet: profilComplet,
        cguAcceptees: cguAcceptees,
        cguUrl: cguUrl,
        photoUrl: photo,
        modeActif: UserMode.fromApi(modeActif),
        statutCompte: AccountStatus.fromApi(statutCompte),
        suspenduJusquAu: suspenduJusquAu,
        kycPassager: KycStatus.fromApi(kyc['passager'] as String?),
        kycConducteur: KycStatus.fromApi(kyc['conducteur'] as String?),
        vehiculeDeclare: _vehiculeDeclare,
      );
}
