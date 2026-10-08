import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Photo ronde d'un utilisateur ; affiche ses initiales si la photo est absente ou en erreur.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.name, this.photoUrl, this.size = 48});

  final String name;
  final String? photoUrl;
  final double size;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: AppColors.border,
      child: Text(
        _initials,
        style: AppTextStyles.cardTitle.copyWith(fontSize: size * 0.34, color: AppColors.primary),
      ),
    );

    return Semantics(
      label: 'Photo de $name',
      image: true,
      child: ClipOval(
        child: photoUrl == null || photoUrl!.isEmpty
            ? fallback
            : Image.network(
                photoUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              ),
      ),
    );
  }
}
