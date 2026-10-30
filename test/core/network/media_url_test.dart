import 'package:flutter_test/flutter_test.dart';
import 'package:kovoit/core/config/env.dart';
import 'package:kovoit/core/network/media_url.dart';

/// Décision Q1 révisée (M-003, F-003) : le backend renvoie `photo` en chemin relatif (`/media/…`).
void main() {
  const api = 'https://api.kovoittg.com/api/v1';

  test('null et vide : renvoyés tels quels', () {
    expect(resolveMediaUrl(null, apiBaseUrl: api), isNull);
    expect(resolveMediaUrl('', apiBaseUrl: api), '');
  });

  test('URL absolue : inchangée', () {
    expect(resolveMediaUrl('https://cdn.exemple.com/p.jpg', apiBaseUrl: api), 'https://cdn.exemple.com/p.jpg');
    expect(resolveMediaUrl('http://10.0.2.2:8000/media/p.jpg', apiBaseUrl: api), 'http://10.0.2.2:8000/media/p.jpg');
  });

  test('chemin relatif : préfixé par l’origine de l’API, sans /api/v1', () {
    expect(
      resolveMediaUrl('/media/photos_profil/moi.jpg', apiBaseUrl: api),
      'https://api.kovoittg.com/media/photos_profil/moi.jpg',
    );
  });

  test('port de l’API conservé (émulateur, téléphone sur le réseau local)', () {
    expect(
      resolveMediaUrl('/media/photos_profil/moi.jpg', apiBaseUrl: 'http://192.168.1.20:8000/api/v1'),
      'http://192.168.1.20:8000/media/photos_profil/moi.jpg',
    );
  });

  test('sans base explicite : origine de Env.apiBaseUrl', () {
    final origin = Uri.parse(Env.apiBaseUrl).origin;
    expect(resolveMediaUrl('/media/p.jpg'), '$origin/media/p.jpg');
    expect(resolveMediaUrl('/media/p.jpg'), isNot(contains('/api/v1')));
  });
}
