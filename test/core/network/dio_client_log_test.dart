import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kovoit/core/config/env.dart';
import 'package:kovoit/core/network/api_exception.dart';
import 'package:kovoit/core/network/api_service.dart';
import 'package:kovoit/core/network/dio_client.dart';
import 'package:kovoit/core/storage/token_storage.dart';
import 'package:kovoit/features/auth/data/datasources/auth_remote_data_source.dart';

import '../../helpers/log_capture.dart';
import '../../helpers/test_app.dart';

const _password = 'Lome-Trajet-2026';

/// Faux adaptateur HTTP : une réponse enregistrée depuis le backend (test/fixtures/backend/)
/// par « MÉTHODE /chemin/ », avec son code HTTP.
class _FakeHttp implements HttpClientAdapter {
  final Map<String, (int, String)> routes = {};
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    final route = routes['${options.method} ${options.path}'];
    if (route == null) throw StateError('Route non simulée : ${options.method} ${options.path}');
    final (status, fixture) = route;
    return ResponseBody.fromString(
      File('test/fixtures/backend/$fixture.json').readAsStringSync(),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// CA0 de F-070 et F-072 sur le chemin de la **vraie** API : le Dio de l'app (avec son
/// `LogInterceptor`, actif en dev) ne journalise jamais le mot de passe, ni en succès ni en erreur.
void main() {
  late _FakeHttp http;
  late AuthRemoteDataSource remote;
  late LogCapture logs;
  late List<String> debugPrints;
  late List<String> prints;
  late Dio dio;

  setUp(() {
    logs = LogCapture.start();
    debugPrints = [];
    final previousDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) => debugPrints.add(message ?? '');
    addTearDown(() => debugPrint = previousDebugPrint);

    final container = ProviderContainer(overrides: [tokenStorageProvider.overrideWithValue(InMemoryTokenStorage())]);
    addTearDown(container.dispose);
    http = _FakeHttp();
    dio = container.read(dioProvider)..httpClientAdapter = http;
    remote = ApiAuthRemoteDataSource(ApiService(dio));
  });

  /// Lance [body] en capturant aussi `print` (sortie console du `Logger` de l'app).
  Future<void> capturePrints(Future<void> Function() body) {
    prints = [];
    return runZoned(body, zoneSpecification: ZoneSpecification(print: (_, _, _, line) => prints.add(line)));
  }

  List<String> allLines() => [...logs.lines, ...debugPrints, ...prints];

  void expectNoPasswordLogged() {
    expect(allLines().where((l) => l.contains(_password)), isEmpty, reason: 'mot de passe trouvé dans les journaux');
    // Sonde : le LogInterceptor a bien écrit dans le journal capturé (sinon le test ne prouve rien).
    expect(logs.lines.where((l) => l.contains('*** Request ***')), isNotEmpty);
    expect(logs.lines.where((l) => l.contains('/auth/')), isNotEmpty);
  }

  /// Le mot de passe est bien parti dans le corps (le test n'est pas vide de sens).
  void expectPasswordSent(String path) {
    final request = http.requests.lastWhere((r) => r.path == path);
    expect((request.data as Map)[AuthFields.motDePasse], _password);
  }

  test('le Dio de l’app est construit en dev, avec son LogInterceptor', () {
    expect(Env.isDev, isTrue, reason: 'le LogInterceptor n’est ajouté qu’en dev (dio_client.dart)');
    expect(dio.interceptors.whereType<LogInterceptor>(), hasLength(1));
  });

  test('inscription : succès puis 400 MOT_DE_PASSE_FAIBLE, mot de passe absent des journaux', () async {
    Future<void> register() => remote.register(
          prenom: 'Ama',
          nom: 'Mensah',
          email: 'ama.mensah@exemple.tg',
          telephone: '+22890112233',
          motDePasse: _password,
          cguAcceptees: true,
        );

    await capturePrints(() async {
      http.routes['POST /auth/inscription/'] = (201, 'auth_code_envoye');
      await register();
      expectPasswordSent('/auth/inscription/');

      http.routes['POST /auth/inscription/'] = (400, 'auth_erreur_mot_de_passe_faible');
      await expectLater(
        register(),
        throwsA(isA<BadRequestApiException>().having((e) => e.code, 'code', 'MOT_DE_PASSE_FAIBLE')),
      );
    });

    expect(logs.lines.where((l) => l.contains('DioException')), isNotEmpty, reason: 'erreur journalisée');
    expectNoPasswordLogged();
  });

  test('connexion : succès puis 401 IDENTIFIANTS_INVALIDES, mot de passe absent des journaux', () async {
    await capturePrints(() async {
      http.routes['POST /auth/connexion/'] = (200, 'auth_session_connexion');
      await remote.login(email: 'ama.mensah@exemple.tg', motDePasse: _password);
      expectPasswordSent('/auth/connexion/');

      http.routes['POST /auth/connexion/'] = (401, 'auth_erreur_identifiants');
      await expectLater(
        remote.login(email: 'ama.mensah@exemple.tg', motDePasse: _password),
        throwsA(isA<UnauthorizedApiException>().having((e) => e.code, 'code', 'IDENTIFIANTS_INVALIDES')),
      );
    });

    expect(logs.lines.where((l) => l.contains('DioException')), isNotEmpty, reason: 'erreur journalisée');
    expectNoPasswordLogged();
  });

  test('réinitialisation : succès puis 400 MOT_DE_PASSE_FAIBLE, mot de passe absent des journaux', () async {
    Future<void> reset() => remote.resetPassword(email: 'ama.mensah@exemple.tg', code: '123456', motDePasse: _password);

    await capturePrints(() async {
      http.routes['POST /auth/mot-de-passe/reinitialiser/'] = (200, 'auth_reinitialise');
      await reset();
      expectPasswordSent('/auth/mot-de-passe/reinitialiser/');

      http.routes['POST /auth/mot-de-passe/reinitialiser/'] = (400, 'auth_erreur_mot_de_passe_faible');
      await expectLater(
        reset(),
        throwsA(isA<BadRequestApiException>().having((e) => e.code, 'code', 'MOT_DE_PASSE_FAIBLE')),
      );
    });

    expect(logs.lines.where((l) => l.contains('DioException')), isNotEmpty, reason: 'erreur journalisée');
    expectNoPasswordLogged();
  });
}
