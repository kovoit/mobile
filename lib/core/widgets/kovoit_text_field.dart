import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Champ de formulaire avec libellé au-dessus et icône à gauche (maquettes).
/// [isPassword] ajoute l'œil pour afficher/masquer. [onTap] + [readOnly] servent
/// aux sélecteurs (date, heure, lieu).
class KovoitTextField extends StatefulWidget {
  const KovoitTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.prefixIcon,
    this.prefixIconColor,
    this.suffix,
    this.isPassword = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.enabled = true,
    this.inputFormatters,
    this.errorText,
    this.autofillHints,
  });

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final Color? prefixIconColor;
  final Widget? suffix;
  final bool isPassword;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool enabled;
  final List<TextInputFormatter>? inputFormatters;

  /// Erreur venue de l'API (ex. `BadRequestApiException.fieldErrors`).
  final String? errorText;
  final Iterable<String>? autofillHints;

  @override
  State<KovoitTextField> createState() => _KovoitTextFieldState();
}

class _KovoitTextFieldState extends State<KovoitTextField> {
  late bool _obscured = widget.isPassword;

  @override
  Widget build(BuildContext context) {
    final field = TextFormField(
      controller: widget.controller,
      obscureText: _obscured,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onTap: widget.onTap,
      readOnly: widget.readOnly,
      enabled: widget.enabled,
      inputFormatters: widget.inputFormatters,
      autofillHints: widget.autofillHints,
      style: AppTextStyles.body,
      decoration: InputDecoration(
        hintText: widget.hint,
        errorText: widget.errorText,
        prefixIcon: widget.prefixIcon == null
            ? null
            : Icon(widget.prefixIcon, size: 22, color: widget.prefixIconColor),
        suffixIcon: widget.isPassword
            ? IconButton(
                onPressed: () => setState(() => _obscured = !_obscured),
                icon: Icon(_obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                tooltip: _obscured ? 'Afficher le mot de passe' : 'Masquer le mot de passe',
              )
            : widget.suffix,
      ),
    );

    if (widget.label == null) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label!, style: AppTextStyles.label),
        const SizedBox(height: AppSpacing.xs),
        field,
      ],
    );
  }
}
