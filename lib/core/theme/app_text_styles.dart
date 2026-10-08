import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typographie des maquettes (Plus Jakarta Sans, à confirmer dans Figma).
abstract final class AppTextStyles {
  static const String fontFamily = 'PlusJakartaSans';

  /// Grand titre d'écran : « Rechercher un trajet », « Espace Conducteur ».
  static const TextStyle display = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    height: 1.2,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );

  /// Titre de section : « Publier un trajet », « Mode de paiement ».
  static const TextStyle title = TextStyle(
    fontFamily: fontFamily,
    fontSize: 19,
    height: 1.3,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  /// Titre de carte : nom du conducteur, libellé d'étape.
  static const TextStyle cardTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 1.3,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    height: 1.4,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  /// Sous-titre gris sous un titre d'écran.
  static const TextStyle subtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  /// Libellé au-dessus d'un champ : « Point de départ ».
  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 1.3,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 1.2,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 1.35,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  /// Montant mis en avant : « 300 FCFA ».
  static const TextStyle price = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    height: 1.2,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );

  /// Chiffres des codes OTP / départ.
  static const TextStyle code = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    height: 1.1,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
}
