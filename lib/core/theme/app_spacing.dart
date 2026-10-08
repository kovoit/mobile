import 'package:flutter/material.dart';

/// Espacements (grille de 4).
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;

  /// Marge latérale des écrans.
  static const double screenPadding = 20;
}

/// Rayons d'arrondi.
abstract final class AppRadius {
  static const double sm = 10;
  static const double field = 14;
  static const double button = 16;
  static const double card = 20;
  static const double pill = 999;
}

/// Ombres douces des cartes et boutons.
abstract final class AppShadows {
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0F14254A), blurRadius: 16, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> button = [
    BoxShadow(color: Color(0x290F2A55), blurRadius: 14, offset: Offset(0, 6)),
  ];
}
