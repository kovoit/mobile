/// Conditions d'utilisation lisibles avant la connexion (écran Inscription).
///
/// Aucune route publique ne renvoie l'adresse : même valeur que `CGU_URL`
/// (`backend/apps/accounts/cgu.py`). Une fois connecté, l'app utilise `cgu_url` du profil.
abstract final class Cgu {
  static const String url = 'https://kovoittg.com/conditions-utilisation/';
}
