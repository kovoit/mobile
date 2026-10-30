import 'package:flutter/material.dart';

import '../../../../core/network/api_exception.dart';

/// Message lisible pour une erreur levée pendant une action d'authentification (texte de l'API).
String authErrorMessage(Object error) => switch (error) {
      ApiException(:final message) => message,
      _ => 'Une erreur inattendue est survenue.',
    };

/// Erreurs par champ renvoyées par l'API, à afficher sous les champs concernés :
/// 400 (`fieldErrors`) et 409 `EMAIL_DEJA_UTILISE` (`erreurs.email`).
Map<String, String> authFieldErrors(Object error) => switch (error) {
      BadRequestApiException(:final fieldErrors) => fieldErrors,
      ConflictApiException(:final details) => {
          for (final entry in details.entries)
            if (entry.value is List && (entry.value as List).isNotEmpty)
              entry.key: (entry.value as List).first.toString()
            else if (entry.value is String)
              entry.key: entry.value as String,
        },
      _ => const {},
    };

/// Code métier du backend (`reponse.code`), `null` hors réponse du serveur.
String? authErrorCode(Object error) => error is ApiException ? error.code : null;

void showAuthError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
}
