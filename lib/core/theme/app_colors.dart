import 'package:flutter/material.dart';

/// Palette relevée sur les maquettes Figma (valeurs à confirmer dans le fichier Figma source).
/// Ne jamais utiliser de couleur en dur dans un écran : passer par cette classe ou le thème.
abstract final class AppColors {
  // Marque
  static const Color primary = Color(0xFF0F2A55); // bleu nuit : boutons, titres, sélection
  static const Color primaryDark = Color(0xFF0B1F40); // fond du splash
  static const Color accent = Color(0xFFF28C28); // orange : liens, repères, progression
  static const Color accentLight = Color(0xFFFFF3E6); // fond des bandeaux « prix recommandé »

  // Statuts
  static const Color success = Color(0xFF22A85A); // vérifié, terminé
  static const Color successLight = Color(0xFFE6F6EC);
  static const Color warning = Color(0xFFE07B12); // à capturer, en attente
  static const Color warningLight = Color(0xFFFFF1E2);
  static const Color error = Color(0xFFD93025);
  static const Color errorLight = Color(0xFFFDECEA);

  // Neutres
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Colors.white;
  static const Color fieldFill = Color(0xFFF3F5F8);
  static const Color border = Color(0xFFE3E8EF);
  static const Color textPrimary = Color(0xFF14254A);
  static const Color textSecondary = Color(0xFF6B7A90);
  static const Color textDisabled = Color(0xFFA9B4C2);
  static const Color mapPlaceholder = Color(0xFFE8EDE6);

  // Marques tierces
  static const Color googleBlue = Color(0xFF4285F4);
}
