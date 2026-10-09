import 'package:flutter/material.dart';

import '../../../../core/widgets/status_chip.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../domain/entities/kyc_dossier.dart';

/// Libellés d'affichage des pièces (maquette « Vérification d'identité »).
extension KycPieceTypeLabels on KycPieceType {
  String get title => switch (this) {
        KycPieceType.photoProfil => 'Photo de profil',
        KycPieceType.identiteRecto => 'Pièce d’identité avant',
        KycPieceType.identiteVerso => 'Pièce d’identité arrière',
        KycPieceType.selfie => 'Selfie',
        KycPieceType.permis => 'Permis de conduire',
        KycPieceType.carteGriseOuAssurance => 'Carte grise ou assurance',
        KycPieceType.photoVehicule => 'Photo du véhicule',
      };

  String get hint => switch (this) {
        KycPieceType.photoProfil => 'votre visage doit être bien visible.',
        KycPieceType.identiteRecto => 'recto de votre carte d’identité.',
        KycPieceType.identiteVerso => 'verso de votre carte d’identité.',
        KycPieceType.selfie => 'capturez un selfie en direct pour confirmer votre identité.',
        KycPieceType.permis => 'recto de votre permis, bien lisible.',
        KycPieceType.carteGriseOuAssurance => 'document du véhicule que vous conduisez.',
        KycPieceType.photoVehicule => 'véhicule entier, immatriculation visible.',
      };

  IconData get icon => switch (this) {
        KycPieceType.photoProfil => Icons.person_outline_rounded,
        KycPieceType.identiteRecto || KycPieceType.identiteVerso => Icons.credit_card_rounded,
        KycPieceType.selfie => Icons.photo_camera_outlined,
        KycPieceType.permis => Icons.badge_outlined,
        KycPieceType.carteGriseOuAssurance => Icons.description_outlined,
        KycPieceType.photoVehicule => Icons.directions_car_filled_outlined,
      };
}

extension KycTypeLabels on KycType {
  String get title => switch (this) {
        KycType.passager => 'Vérification d’identité',
        KycType.conducteur => 'Dossier conducteur',
      };

  String get subtitle => switch (this) {
        KycType.passager => 'Pour plus de sécurité, nous avons besoin de vérifier votre identité.',
        KycType.conducteur => 'Ces pièces nous permettent de vérifier votre véhicule avant vos premiers trajets.',
      };
}

/// Pastille de statut d'un dossier KYC (valeur renvoyée par l'API).
StatusChip kycStatusChip(KycStatus status) => switch (status) {
      KycStatus.verifie => const StatusChip(label: 'Vérifié', tone: StatusTone.success, icon: Icons.verified_outlined),
      KycStatus.enAttente =>
        const StatusChip(label: 'En attente', tone: StatusTone.warning, icon: Icons.hourglass_top_rounded),
      KycStatus.rejete => const StatusChip(label: 'Refusé', tone: StatusTone.error, icon: Icons.error_outline_rounded),
      KycStatus.nonVerifie => const StatusChip(label: 'À compléter', tone: StatusTone.warning),
    };
