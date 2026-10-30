import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Message d'erreur général d'un formulaire (texte de l'API), sous le bouton ou le code.
class FormErrorText extends StatelessWidget {
  const FormErrorText(this.message, {super.key, this.textAlign = TextAlign.center});

  final String message;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) => Text(
        message,
        textAlign: textAlign,
        style: AppTextStyles.caption.copyWith(color: AppColors.error),
      );
}
