import 'package:flutter/material.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/repositories/auth_repository.dart';

/// Message lisible pour une erreur levée pendant une action d'authentification.
String authErrorMessage(Object error) => switch (error) {
      ApiException(:final message) => message,
      GoogleSignInUnavailableException(:final message) => message,
      _ => 'Une erreur inattendue est survenue.',
    };

/// Erreurs par champ renvoyées par l'API (400), à afficher sous les champs concernés.
Map<String, String> authFieldErrors(Object error) =>
    error is BadRequestApiException ? error.fieldErrors : const {};

void showAuthError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
}
