/// Validateurs de formulaires (compatibles avec `TextFormField.validator`).
/// Ils ne remplacent pas la validation du backend, qui fait foi.
abstract final class Validators {
  static String? required(String? value, {String message = 'Ce champ est obligatoire.'}) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  static final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return "L'adresse e-mail est obligatoire.";
    if (!_email.hasMatch(value.trim())) return 'Adresse e-mail invalide.';
    return null;
  }

  /// Numéro mobile togolais : 8 chiffres commençant par 7 ou 9, avec ou sans +228.
  static String? togoPhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Le numéro de téléphone est obligatoire.';
    if (normalizeTogoPhone(value) == null) return 'Numéro invalide (ex. +228 90 12 34 56).';
    return null;
  }

  /// Retourne le numéro au format E.164 (`+22890123456`) ou `null` s'il est invalide.
  static String? normalizeTogoPhone(String value) {
    var digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('00228')) digits = digits.substring(5);
    if (digits.startsWith('228') && digits.length == 11) digits = digits.substring(3);
    if (!RegExp(r'^[79]\d{7}$').hasMatch(digits)) return null;
    return '+228$digits';
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Le mot de passe est obligatoire.';
    if (value.length < 8) return 'Au moins 8 caractères.';
    return null;
  }

  /// Code numérique de longueur fixe : OTP SMS (6) ou code de départ (4).
  static String? numericCode(String? value, {required int length}) {
    if (value == null || !RegExp('^\\d{$length}\$').hasMatch(value)) {
      return 'Le code doit contenir $length chiffres.';
    }
    return null;
  }
}
