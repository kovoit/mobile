import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Saisie d'un code numérique en cases séparées.
/// - OTP SMS : [length] = 6 (écran « Vérification SMS »).
/// - Code de départ saisi par le conducteur : [length] = 4.
/// Un seul champ texte invisible capte la saisie (collage et remplissage SMS compris).
class OtpCodeInput extends StatefulWidget {
  const OtpCodeInput({
    super.key,
    this.length = 6,
    this.onChanged,
    this.onCompleted,
    this.autofocus = false,
    this.hasError = false,
    this.controller,
  });

  final int length;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;
  final bool autofocus;
  final bool hasError;
  final TextEditingController? controller;

  @override
  State<OtpCodeInput> createState() => _OtpCodeInputState();
}

const double _maxBoxWidth = 52;

class _OtpCodeInputState extends State<OtpCodeInput> {
  late final TextEditingController _controller = widget.controller ?? TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_rebuild);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    if (widget.controller == null) _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  void _onTextChanged() {
    final code = _controller.text;
    widget.onChanged?.call(code);
    if (code.length == widget.length) widget.onCompleted?.call(code);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final code = _controller.text;
    return Semantics(
      label: 'Code à ${widget.length} chiffres',
      textField: true,
      child: GestureDetector(
        onTap: _focusNode.requestFocus,
        child: Stack(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: _maxBoxWidth),
                      child: _CodeBox(
                      digit: i < code.length ? code[i] : '',
                      isActive: _focusNode.hasFocus &&
                          (i == code.length || (i == widget.length - 1 && code.length == widget.length)),
                      hasError: widget.hasError,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            Positioned.fill(
              child: Opacity(
                opacity: 0,
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: widget.autofocus,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  showCursor: false,
                  enableInteractiveSelection: false,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(widget.length),
                  ],
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    filled: false,
                    counterText: '',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CodeBox extends StatelessWidget {
  const _CodeBox({required this.digit, required this.isActive, required this.hasError});

  final String digit;
  final bool isActive;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError
        ? AppColors.error
        : isActive
            ? AppColors.primary
            : AppColors.border;
    return AspectRatio(
      aspectRatio: 0.82,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.fieldFill,
          borderRadius: BorderRadius.circular(AppRadius.field),
          border: Border.all(color: borderColor, width: isActive || hasError ? 1.8 : 1),
        ),
        child: Text(digit, style: AppTextStyles.code),
      ),
    );
  }
}
