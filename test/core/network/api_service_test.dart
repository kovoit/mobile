import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kovoit/core/constants/api_constants.dart';
import 'package:kovoit/core/network/api_exception.dart';
import 'package:kovoit/core/network/api_service.dart';
import 'package:kovoit/core/network/auth_interceptor.dart';
import 'package:kovoit/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:kovoit/features/auth/data/repositories/auth_repository_impl.dart';

import '../../helpers/test_app.dart';

typedef _Handler = (int, Map<String, dynamic>) Function(RequestOptions options);

/// Faux serveur : une réponse par chemin, et l'historique des requêtes reçues.
class _FakeServer implements HttpClientAdapter {
  final handlers = <String, _Handler>{};
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    final handler = handlers[options.path];
    if (handler == null) throw StateError('Route non simulée : ${options.path}');
    final (status, body) = handler(options);
    return ResponseBody.fromString(jsonEncode(body), status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _ok(Object? reponse, [String message = 'OK']) =>
    {'statut': 'success', 'message': message, 'reponse': reponse};

Map<String, dynamic> _failed(String message, String code, [Map<String, dynamic>? erreurs]) => {
      'statut': 'failed',
      'message': message,
      'reponse': {'code': code, 'erreurs': ?erreurs},
    };

Map<String, dynamic> _profil({String telephone = '+22890123456'}) => {
      'id': '3f1c2b9e-0000-4000-8000-000000000001',
      'email': 'ama@kovoit.tg',
      'telephone': telephone,
      'nom': 'Mensah',
      'prenom': 'Ama',
      'photo': null,
      'email_verifie': true,
      'mode_actif': 'passager',
      'statut_compte': 'actif',
      'suspendu_jusqu_au': null,
      'profil_complet': telephone.isNotEmpty,
      'kyc': {'passager': 'verifie', 'conducteur': 'non_verifie'},
      'etat': {
        'badge_kyc': false,
        'mode_conducteur': {'disponible': false, 'kyc_conducteur_verifie': false, 'vehicule_declare': true},
        'alertes': <Object>[],
      },
    };

AuthRepositoryImpl _repository(ApiService api, InMemoryTokenStorage tokens) =>
    AuthRepositoryImpl(remote: ApiAuthRemoteDataSource(api), tokenStorage: tokens, capture: FakeCaptureService());

void main() {
  late _FakeServer server;
  late InMemoryTokenStorage tokens;
  late ApiService api;
  late int sessionExpired;

  setUp(() {
    server = _FakeServer();
    tokens = InMemoryTokenStorage();
    sessionExpired = 0;
    Dio client() => Dio(BaseOptions(baseUrl: 'http://test/api/v1'))..httpClientAdapter = server;
    final dio = client()
      ..interceptors.add(
        AuthInterceptor(tokenStorage: tokens, refreshClient: client(), onSessionExpired: () => sessionExpired++),
      );
    api = ApiService(dio);
  });

  group('ApiService', () {
    test('déballe reponse et le message', () async {
      server.handlers[ApiEndpoints.sante] = (_) => (200, _ok({'version': '1.0'}, 'Service opérationnel.'));

      final response = await api.send(ApiEndpoints.sante, method: 'GET', parse: ApiService.asMap);

      expect(response.data['version'], '1.0');
      expect(response.message, 'Service opérationnel.');
    });

    test('lit une page paginée', () async {
      server.handlers[ApiEndpoints.reservations] = (options) {
        expect(options.queryParameters, {'statut': 'acceptee', 'page': 2});
        return (200, _ok({'count': 21, 'next': null, 'previous': 'p1', 'results': [{'id': 'a'}]}));
      };

      final page = await api.getPage(
        ApiEndpoints.reservations,
        query: {'statut': 'acceptee'},
        page: 2,
        item: (json) => json['id'] as String,
      );

      expect(page.count, 21);
      expect(page.results, ['a']);
      expect(page.hasNext, isFalse);
    });

    test('une erreur enveloppée devient une ApiException avec code et erreurs de champ', () async {
      server.handlers[ApiEndpoints.moi] = (_) => (
            400,
            _failed('Données invalides.', 'DONNEES_INVALIDES', {
              'telephone': ['Numéro togolais attendu.'],
            }),
          );

      await expectLater(
        api.patch(ApiEndpoints.moi, body: {'telephone': '12'}, parse: ApiService.asMap),
        throwsA(
          isA<BadRequestApiException>()
              .having((e) => e.code, 'code', 'DONNEES_INVALIDES')
              .having((e) => e.fieldErrors, 'fieldErrors', {'telephone': 'Numéro togolais attendu.'}),
        ),
      );
    });

    test('409 métier : le code (PLUS_DE_PLACE) est exposé', () async {
      server.handlers[ApiEndpoints.reservations] =
          (_) => (409, _failed('Plus de place disponible.', 'PLUS_DE_PLACE'));

      await expectLater(
        api.post(ApiEndpoints.reservations, body: const {}, parse: ApiService.asMap),
        throwsA(isA<ConflictApiException>().having((e) => e.code, 'code', 'PLUS_DE_PLACE')),
      );
    });
  });

  group('AuthInterceptor', () {
    test('ajoute le Bearer, rafraîchit sur 401 et enregistre le refresh tourné', () async {
      tokens
        ..access = 'access-expire'
        ..refresh = 'refresh-1';
      server.handlers[ApiEndpoints.moi] = (options) => options.headers['Authorization'] == 'Bearer access-2'
          ? (200, _ok(_profil()))
          : (401, _failed('Session invalide ou expirée. Reconnectez-vous.', 'AUTHENTIFICATION_ECHOUEE'));
      server.handlers[ApiEndpoints.jetonRafraichir] = (options) {
        expect(options.data, {'refresh': 'refresh-1'});
        return (200, _ok({'access': 'access-2', 'refresh': 'refresh-2'}));
      };

      final repo = _repository(api, tokens);
      final user = await repo.refreshUser();

      expect(user.prenom, 'Ama');
      expect(tokens.access, 'access-2');
      expect(tokens.refresh, 'refresh-2');
      expect(server.requests.where((r) => r.path == ApiEndpoints.jetonRafraichir), hasLength(1));
    });

    test('refresh refusé : session effacée et signal de session expirée', () async {
      tokens
        ..access = 'a'
        ..refresh = 'r';
      server.handlers[ApiEndpoints.moi] = (_) => (401, _failed('Non authentifié.', 'NON_AUTHENTIFIE'));
      server.handlers[ApiEndpoints.jetonRafraichir] =
          (_) => (401, _failed('Session expirée.', 'SESSION_EXPIREE'));

      final repo = _repository(api, tokens);

      expect(await repo.restoreSession(), isNull);
      expect(tokens.access, isNull);
      expect(tokens.refresh, isNull);
      expect(sessionExpired, 1);
    });

    test('refresh en 400 (corps refusé) : session effacée et signal de session expirée', () async {
      tokens
        ..access = 'a'
        ..refresh = 'r';
      server.handlers[ApiEndpoints.moi] = (_) => (401, _failed('Non authentifié.', 'NON_AUTHENTIFIE'));
      server.handlers[ApiEndpoints.jetonRafraichir] = (_) => (
            400,
            _failed('Données invalides.', 'DONNEES_INVALIDES', {
              'refresh': ['Ce champ ne peut être vide.'],
            }),
          );

      final repo = _repository(api, tokens);

      expect(await repo.restoreSession(), isNull);
      expect(tokens.access, isNull);
      expect(tokens.refresh, isNull);
      expect(sessionExpired, 1);
    });

    test('refresh injoignable : jetons conservés, aucune session expirée', () async {
      tokens
        ..access = 'a'
        ..refresh = 'r';
      server.handlers[ApiEndpoints.moi] =
          (_) => (401, _failed('Session invalide ou expirée. Reconnectez-vous.', 'AUTHENTIFICATION_ECHOUEE'));
      server.handlers[ApiEndpoints.jetonRafraichir] =
          (o) => throw DioException.connectionError(requestOptions: o, reason: 'hors ligne');

      final repo = _repository(api, tokens);

      await expectLater(repo.restoreSession(), throwsA(isA<NetworkApiException>()));
      expect(tokens.access, 'a');
      expect(tokens.refresh, 'r');
      expect(sessionExpired, 0);
    });

    test('refresh en 503 : jetons conservés, aucune session expirée', () async {
      tokens
        ..access = 'a'
        ..refresh = 'r';
      server.handlers[ApiEndpoints.moi] =
          (_) => (401, _failed('Session invalide ou expirée. Reconnectez-vous.', 'AUTHENTIFICATION_ECHOUEE'));
      server.handlers[ApiEndpoints.jetonRafraichir] =
          (_) => (503, _failed('Service indisponible.', 'SERVICE_INDISPONIBLE'));

      final repo = _repository(api, tokens);

      await expectLater(repo.restoreSession(), throwsA(isA<ServerApiException>()));
      expect(tokens.access, 'a');
      expect(tokens.refresh, 'r');
      expect(sessionExpired, 0);
    });

    test('envoi multipart rejoué après refresh', () async {
      tokens
        ..access = 'access-expire'
        ..refresh = 'refresh-1';
      final pieces = ApiEndpoints.kycPieces('conducteur');
      server.handlers[pieces] = (options) => options.headers['Authorization'] == 'Bearer access-2'
          ? (201, _ok({'dossier': {'type': 'conducteur', 'statut': 'en_cours'}}))
          : (401, _failed('Session invalide ou expirée. Reconnectez-vous.', 'AUTHENTIFICATION_ECHOUEE'));
      server.handlers[ApiEndpoints.jetonRafraichir] =
          (_) => (200, _ok({'access': 'access-2', 'refresh': 'refresh-2'}));

      final response = await api.send(
        pieces,
        method: 'POST',
        body: FormData.fromMap({
          'type_piece': 'identite',
          'fichier': MultipartFile.fromBytes([0xFF, 0xD8], filename: 'p.jpg'),
        }),
        parse: ApiService.asMap,
      );

      expect(response.data['dossier'], isA<Map<String, dynamic>>());
      final sent = server.requests.where((r) => r.path == pieces).toList();
      expect(sent, hasLength(2));
      expect(sent.last.headers['Authorization'], 'Bearer access-2');
      expect(tokens.refresh, 'refresh-2');
    });
  });

  group('AuthRepositoryImpl + ApiAuthRemoteDataSource', () {
    test('vérification de l’e-mail : sans jeton envoyé, jetons stockés, profil mappé', () async {
      tokens.access = 'ancien';
      server.handlers[ApiEndpoints.inscriptionVerifier] = (options) {
        expect(options.headers.containsKey('Authorization'), isFalse);
        expect(options.data, {'email': 'ama@kovoit.tg', 'code': '123456'});
        return (
          200,
          _ok({'utilisateur': _profil(), 'nouveau_compte': true, 'access': 'A', 'refresh': 'R'}),
        );
      };

      final user = await _repository(api, tokens).verifyEmail(email: ' Ama@Kovoit.tg ', code: '123456');

      expect(user.id, '3f1c2b9e-0000-4000-8000-000000000001');
      expect(user.profilComplet, isTrue);
      expect(user.vehiculeDeclare, isTrue);
      expect(tokens.access, 'A');
      expect(tokens.refresh, 'R');
    });

    test('connexion : 401 IDENTIFIANTS_INVALIDES sans refresh ni fin de session', () async {
      tokens
        ..access = 'A'
        ..refresh = 'R';
      server.handlers[ApiEndpoints.connexion] = (options) {
        expect(options.headers.containsKey('Authorization'), isFalse);
        return (401, _failed('Email ou mot de passe incorrect.', 'IDENTIFIANTS_INVALIDES'));
      };

      await expectLater(
        _repository(api, tokens).login(email: 'ama@kovoit.tg', password: 'mauvais'),
        throwsA(isA<UnauthorizedApiException>().having((e) => e.code, 'code', 'IDENTIFIANTS_INVALIDES')),
      );
      expect(server.requests.map((r) => r.path), [ApiEndpoints.connexion]);
      expect(sessionExpired, 0);
      expect(tokens.access, 'A');
      expect(tokens.refresh, 'R');
    });

    test('les 6 routes auth/… : un 401 ne déclenche jamais de refresh', () async {
      tokens.refresh = 'R';
      for (final path in [
        ApiEndpoints.inscription,
        ApiEndpoints.inscriptionVerifier,
        ApiEndpoints.inscriptionRenvoyerCode,
        ApiEndpoints.connexion,
        ApiEndpoints.motDePasseOublie,
        ApiEndpoints.motDePasseReinitialiser,
      ]) {
        server.handlers[path] = (_) => (401, _failed('Refusé.', 'IDENTIFIANTS_INVALIDES'));
        await expectLater(
          api.post<void>(path, body: const {}, parse: (_) {}),
          throwsA(isA<UnauthorizedApiException>()),
          reason: path,
        );
      }
      expect(server.requests.where((r) => r.path == ApiEndpoints.jetonRafraichir), isEmpty);
      expect(sessionExpired, 0);
      expect(tokens.refresh, 'R');
    });

    test('code faux : pas de refresh tenté, code métier remonté', () async {
      tokens.refresh = 'ancien';
      server.handlers[ApiEndpoints.inscriptionVerifier] =
          (_) => (400, _failed('Code invalide ou expiré.', 'CODE_OTP_INVALIDE'));

      await expectLater(
        _repository(api, tokens).verifyEmail(email: 'a@b.tg', code: '000000'),
        throwsA(isA<BadRequestApiException>().having((e) => e.code, 'code', 'CODE_OTP_INVALIDE')),
      );
      expect(server.requests.map((r) => r.path), [ApiEndpoints.inscriptionVerifier]);
    });

    test('déconnexion : refresh envoyé puis session locale effacée, même hors ligne', () async {
      tokens
        ..access = 'A'
        ..refresh = 'R';
      server.handlers[ApiEndpoints.deconnexion] = (_) => (500, {'detail': 'panne'});

      await _repository(api, tokens).logout();

      expect(server.requests.single.data, {'refresh': 'R'});
      expect(tokens.access, isNull);
      expect(tokens.refresh, isNull);
    });
  });
}
