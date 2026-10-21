import 'package:flutter/material.dart';

import '../../../../core/widgets/status_chip.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../domain/entities/kyc_dossier.dart';

/// Libellés d'affichage des emplacements de pièces (maquette « Vérification d'identité »).
extension KycSlotLabels on KycSlot {
  String get title => switch (this) {
        KycSlot.identite => 'Pièce d’identité',
        KycSlot.selfie => 'Selfie',
        KycSlot.permis => 'Permis de conduire',
        KycSlot.vehiculeDocument => 'Carte grise ou assurance',
        KycSlot.photoVehicule => 'Photo du véhicule',
      };

  /// Libellé court de la barre d'avancement.
  String get stepLabel => switch (this) {
        KycSlot.identite => 'Identité',
        KycSlot.selfie => 'Selfie',
        KycSlot.permis => 'Permis',
        KycSlot.vehiculeDocument => 'Document',
        KycSlot.photoVehicule => 'Véhicule',
      };

  String get hint => switch (this) {
        KycSlot.identite => 'carte d’identité, passeport ou carte d’électeur, bien lisible.',
        KycSlot.selfie => 'capturez un selfie en direct pour confirmer votre identité.',
        KycSlot.permis => 'recto de votre permis, bien lisible.',
        KycSlot.vehiculeDocument => 'l’un des deux documents du véhicule que vous conduisez.',
        KycSlot.photoVehicule => 'véhicule entier, immatriculation visible.',
      };

  IconData get icon => switch (this) {
        KycSlot.identite => Icons.credit_card_rounded,
        KycSlot.selfie => Icons.photo_camera_outlined,
        KycSlot.permis => Icons.badge_outlined,
        KycSlot.vehiculeDocument => Icons.description_outlined,
        KycSlot.photoVehicule => Icons.directions_car_filled_outlined,
      };
}

extension KycPieceTypeLabels on KycPieceType {
  String get title => switch (this) {
        KycPieceType.identite => 'Pièce d’identité',
        KycPieceType.selfie => 'Selfie',
        KycPieceType.permis => 'Permis de conduire',
        KycPieceType.carteGrise => 'Carte grise',
        KycPieceType.assurance => 'Attestation d’assurance',
        KycPieceType.photoVehicule => 'Photo du véhicule',
      };
}

extension KycTypeLabels on KycType {
  String get title => switch (this) {
        KycType.passager => 'Vérification d’identité',
        KycType.conducteur => 'Dossier conducteur',
      };

  String get subtitle => switch (this) {
        KycType.passager => 'Pour plus de sécurité, nous avons besoin de vérifier votre identité.',
        KycType.conducteur => 'Votre identité, votre permis et votre véhicule sont vérifiés avant vos premiers trajets.',
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
