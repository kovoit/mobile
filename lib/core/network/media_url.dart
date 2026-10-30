import '../config/env.dart';

/// URL d'un fichier média (photo de profil, du conducteur, du véhicule) prête pour `Image.network`.
///
/// Le backend renvoie `photo` en chemin relatif à son serveur (`/media/photos_profil/….jpg`) sur
/// toutes ses routes (décision Q1 révisée, M-003). Ce chemin est complété avec l'**origine** de
/// l'API (schéma, hôte, port), sans le préfixe `/api/v1` : `http://10.0.2.2:8000/media/…`.
///
/// - `null` ou vide : renvoyé tel quel (pas de photo) ;
/// - URL absolue (`http://`, `https://`) : inchangée ;
/// - chemin commençant par `/` : préfixé par l'origine de [apiBaseUrl] (par défaut [Env.apiBaseUrl]).
///
/// Résolution d'URL uniquement, à appeler dans la couche `data` (DTO → entité), jamais dans un widget.
String? resolveMediaUrl(String? url, {String? apiBaseUrl}) {
  if (url == null || url.isEmpty || !url.startsWith('/')) return url;
  final base = Uri.tryParse(apiBaseUrl ?? Env.apiBaseUrl);
  if (base == null || !(base.isScheme('http') || base.isScheme('https')) || base.host.isEmpty) return url;
  // URL sans schéma (`//hote/…`) : même schéma que l'API.
  if (url.startsWith('//')) return '${base.scheme}:$url';
  return '${base.origin}$url';
}
