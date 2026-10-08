import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Logo Kovoit. Avec [framed], il est posé dans une tuile blanche arrondie
/// (écrans Connexion / Inscription).
class KovoitLogo extends StatelessWidget {
  const KovoitLogo({super.key, this.size = 72, this.framed = false});

  static const String assetPath = 'assets/images/logo_kovoit.png';

  final double size;
  final bool framed;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: 'Logo Kovoit',
    );
    if (!framed) return image;

    return Container(
      padding: EdgeInsets.all(size * 0.14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: AppShadows.card,
      ),
      child: image,
    );
  }
}
