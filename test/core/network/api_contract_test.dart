import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kovoit/core/config/env.dart';
import 'package:kovoit/core/constants/api_constants.dart';
import 'package:kovoit/core/network/api_exception.dart';
import 'package:kovoit/core/network/api_service.dart';
import 'package:kovoit/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:kovoit/features/booking/data/datasources/booking_remote_data_source.dart';
import 'package:kovoit/features/driver/data/datasources/driver_remote_data_source.dart';
import 'package:kovoit/features/driver/data/dto/driver_dto.dart';
import 'package:kovoit/features/driver/domain/entities/driver_trip.dart';
import 'package:kovoit/features/driver/domain/entities/price_breakdown.dart';
import 'package:kovoit/features/notifications/data/devices_repository_impl.dart';
import 'package:kovoit/features/notifications/data/notifications_remote_data_source.dart';
import 'package:kovoit/features/rating/data/rating_repository_impl.dart';
import 'package:kovoit/features/report/data/report_repository_impl.dart';
import 'package:kovoit/features/report/domain/report_repository.dart';
import 'package:kovoit/features/search/data/datasources/search_remote_data_source.dart';
import 'package:kovoit/features/trip/data/datasources/trip_remote_data_source.dart';
import 'package:kovoit/features/trip/domain/entities/geo_place.dart';
import 'package:kovoit/features/trip/domain/entities/trip.dart';
import 'package:kovoit/features/vehicle/data/datasources/vehicle_remote_data_source.dart';
import 'package:kovoit/features/wallet/data/wallet_remote_data_source.dart';
import 'package:kovoit/features/wallet/domain/wallet.dart';

/// Contrat entre l'app et le **vrai** backend : les sources de données réelles (pas les fausses)
/// appellent les routes Django avec les bons corps, et décodent les réponses enregistrées depuis
/// le backend (test/fixtures/backend/*.json, produites par ses serializers).
///
/// Régénérer les fixtures après un changement d'API : voir test/fixtures/backend/README.md.
class _Backend implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  final Map<String, String> routes = {}; // « MÉTHODE /chemin/ » → fichier de fixture
  int status = 200;

  RequestOptions get last => requests.last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final key = '${options.method} ${options.path}';
    final fixture = routes[key];
    final body = fixture == null
        ? '{"statut": "success", "message": "OK.", "reponse": null}'
        : File('test/fixtures/backend/$fixture.json').readAsStringSync();
    return ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _Backend backend;
  late ApiService api;

  setUp(() {
    backend = _Backend();
    api = ApiService(Dio(BaseOptions(baseUrl: 'https://api.kovoit.tg/api/v1'))..httpClientAdapter = backend);
  });

  Map<String, dynamic> body() => Map<String, dynamic>.from(backend.last.data as Map);

  test('lieux connus et recherche de trajets', () async {
    final remote = ApiSearchRemoteDataSource(api);
    backend.routes['GET /lieux/'] = 'lieux';
    final lieux = await remote.searchPlaces('univ');
    expect(backend.last.queryParameters, {'q': 'univ'});
    expect(lieux.single.toEntity().type, GeoPlaceType.repere);

    backend.routes['GET /trajets/recherche/'] = 'recherche';
    final matches = await remote.search((
      departLat: 6.175,
      departLng: 1.17,
      arriveeLat: 6.13,
      arriveeLng: 1.222,
      dateHeure: DateTime.utc(2026, 10, 22, 9),
      typeVehicule: null,
    ));
    expect(
      backend.last.queryParameters.keys,
      containsAll(['depart_lat', 'depart_lng', 'arrivee_lat', 'arrivee_lng', 'date_heure']),
    );
    expect(backend.last.queryParameters.keys, isNot(contains('places')), reason: 'une réservation = une place');
    expect(backend.last.queryParameters.keys, isNot(contains('type_vehicule')), reason: '« Tous » : paramètre absent');
    final trip = matches.single.toEntity();
    expect(trip.matchedPickupId, matches.single.pointPropose.id);
    expect(trip.walkingDistanceKm, isNotNull);
    expect(trip.driver.verifie, isTrue);
    expect(trip.prixPassager, matches.single.prixPassager, reason: 'prix du passager renvoyé par la recherche');
  });

  test('recherche filtrée par type de véhicule (contrat C2, F-055)', () async {
    backend.routes['GET /trajets/recherche/'] = 'recherche';
    await ApiSearchRemoteDataSource(api).search((
      departLat: 6.175,
      departLng: 1.17,
      arriveeLat: 6.13,
      arriveeLng: 1.222,
      dateHeure: DateTime.utc(2026, 10, 22, 9),
      typeVehicule: 'moto',
    ));
    expect(backend.last.queryParameters['type_vehicule'], 'moto');
  });

  test('recherche filtrée sur les voitures : type_vehicule=voiture envoyé (contrat C2, F-055)', () async {
    backend.routes['GET /trajets/recherche/'] = 'recherche';
    await ApiSearchRemoteDataSource(api).search((
      departLat: 6.175,
      departLng: 1.17,
      arriveeLat: 6.13,
      arriveeLng: 1.222,
      dateHeure: DateTime.utc(2026, 10, 22, 9),
      typeVehicule: 'voiture',
    ));
    expect(backend.last.path, '/trajets/recherche/');
    expect(backend.last.queryParameters['type_vehicule'], 'voiture');
    expect(backend.last.uri.query, contains('type_vehicule=voiture'));
  });

  test('recherche : photos relatives du conducteur et du véhicule complétées (Q1 révisée, F-003)', () async {
    backend.routes['GET /trajets/recherche/'] = 'recherche_photo';
    final matches = await ApiSearchRemoteDataSource(api).search((
      departLat: 6.175,
      departLng: 1.17,
      arriveeLat: 6.13,
      arriveeLng: 1.222,
      dateHeure: DateTime.utc(2026, 10, 22, 9),
      typeVehicule: null,
    ));
    final trip = matches.single.toEntity();
    final origin = Uri.parse(Env.apiBaseUrl).origin;
    expect(matches.single.trajet.conducteur.photo, '/media/photos_profil/kodjo.jpg', reason: 'le backend renvoie /media/…');
    expect(trip.driver.photoUrl, '$origin/media/photos_profil/kodjo.jpg');
    expect(Uri.parse(trip.driver.photoUrl!).isAbsolute, isTrue);
    expect(trip.driver.photoUrl, isNot(contains('/api/v1')));
    expect(trip.vehicle.photoUrl, '$origin/media/vehicules/corolla.jpg');
  });

  test('détail d’un trajet avec l’aperçu du paiement', () async {
    backend.routes['GET /trajets/T/'] = 'trajet_detail';
    const query = (id: 'T', pickupId: 'P', arriveeLat: 6.13, arriveeLng: 1.22);
    final trip = (await ApiTripRemoteDataSource(api).fetchTrip(query)).toEntity();
    expect(backend.last.queryParameters, {'point_id': 'P', 'arrivee_lat': 6.13, 'arrivee_lng': 1.22});
    expect(trip.payment, isNotNull);
    expect(trip.payment!.montantTotal, trip.prixPassager, reason: 'le paiement porte sur le prix du passager');
    expect(trip.pickupPoints, isNotEmpty);
    expect(trip.trace, isNull, reason: 'fixture sans `trace` (trajet publié avant les tracés)');
  });

  test('détail d’un trajet : photos relatives du conducteur et du véhicule complétées (Q1 révisée, F-003)', () async {
    backend.routes['GET /trajets/T/'] = 'trajet_detail_photo';
    final trip = (await ApiTripRemoteDataSource(api).fetchTrip((id: 'T', pickupId: null, arriveeLat: null, arriveeLng: null)))
        .toEntity();
    final origin = Uri.parse(Env.apiBaseUrl).origin;
    expect(trip.driver.photoUrl, '$origin/media/photos_profil/kodjo.jpg');
    expect(Uri.parse(trip.driver.photoUrl!).isAbsolute, isTrue);
    expect(trip.driver.photoUrl, isNot(contains('/api/v1')));
    expect(trip.vehicle.photoUrl, '$origin/media/vehicules/corolla.jpg');
  });

  test('détail d’un trajet avec le tracé de la route (contrat C1, F-057)', () async {
    backend.routes['GET /trajets/T/'] = 'trajet_detail_trace';
    final trip = (await ApiTripRemoteDataSource(api).fetchTrip((id: 'T', pickupId: null, arriveeLat: null, arriveeLng: null)))
        .toEntity();
    expect(trip.trace, isNotNull);
    expect(trip.trace!.source, TraceSource.routage);
    expect(trip.trace!.points, [(lat: 6.1745, lng: 1.169), (lat: 6.17501, lng: 1.17003), (lat: 6.13, lng: 1.222)]);
    expect(trip.trace!.points.first, (lat: trip.depart.lat, lng: trip.depart.lng), reason: 'du départ…');
    expect(trip.trace!.points.last, (lat: trip.arrivee.lat, lng: trip.arrivee.lng), reason: '…à l’arrivée');
    expect(trip.prixPassager, 300, reason: 'prix inchangé par le tracé');
  });

  test('réservation : demande, liste, suivi avec code, annulation, partage, confirmation', () async {
    final remote = ApiBookingRemoteDataSource(api);
    backend.routes['POST /reservations/'] = 'reservation_creee';
    final created = await remote.request(
      tripId: 'T',
      pickupPointId: 'P',
      arrivee: (libelle: 'Grand Marché', lat: 6.13, lng: 1.222),
    );
    expect(body(), {
      'trajet_id': 'T',
      'point_id': 'P',
      'arrivee_lat': 6.13,
      'arrivee_lng': 1.222,
      'arrivee_libelle': 'Grand Marché',
    });
    expect(created.toEntity().departureCode, isNull);

    backend.routes['GET /reservations/'] = 'reservations_passager';
    expect(await remote.fetchMine(), hasLength(1));

    backend.routes['GET /reservations/R/'] = 'reservation_acceptee';
    expect((await remote.fetch('R')).toEntity().departureCode, matches(RegExp(r'^\d{4}$')));

    backend.routes['POST /reservations/R/partage/'] = 'partage';
    expect((await remote.share('R'))['chemin'], startsWith('/suivi/'));

    await remote.cancel('R').catchError((Object _) => created);
    expect(backend.last.path, '/reservations/R/annuler/');
    await remote.confirm('R').catchError((Object _) => created);
    expect(backend.last.path, '/reservations/R/confirmer-arrivee/');
  });

  test('conducteur : publication, trajets, demandes, code de départ, absence, économies', () async {
    final remote = ApiDriverRemoteDataSource(api);
    backend.routes['POST /trajets/'] = 'trajet_publie';
    final draft = TripDraft(
      depart: const GeoPlace(libelle: 'Adidogomé', lat: 6.1745, lng: 1.169),
      arrivee: const GeoPlace(libelle: 'Grand Marché', lat: 6.13, lng: 1.222),
      pickupPoints: const [GeoPlace(libelle: 'Carrefour Adidogomé', lat: 6.175, lng: 1.17)],
      departureAt: DateTime.utc(2099, 1, 1, 7, 30),
      places: 2,
    );
    backend.routes['POST /trajets/estimation/'] = 'estimation';
    final query = (vehiculeId: 'V', depart: draft.depart, arrivee: draft.arrivee, places: 2);
    final devis = PriceBreakdown.fromJson(await remote.estimate(estimationBody(query)));
    expect(body().keys, unorderedEquals(['vehicule_id', 'depart_lat', 'depart_lng', 'arrivee_lat', 'arrivee_lng', 'places']));
    expect(devis.passagersPrevus, 2);
    expect(devis.commissionPlace + devis.netConducteurPlace, devis.prixPlace);
    expect(devis.prixCarburantLitre, 817);

    final published = await remote.publish(publicationBody(draft, vehiculeId: 'V'));
    final pricing = published.toEntity().pricing!;
    expect(pricing.prixPlace, published.toEntity().prixPlace, reason: 'prix figé avec son calcul');
    expect(
      body().keys,
      containsAll(['vehicule_id', 'depart_lat', 'depart_libelle', 'arrivee_lat', 'depart_le', 'places', 'points']),
    );
    expect(published.toEntity().status, TripStatus.publie);

    backend.routes['GET /trajets/mes-trajets/'] = 'mes_trajets';
    expect((await remote.myTrips()).single.nbDemandes, 0, reason: 'demande déjà acceptée dans la fixture');

    backend.routes['GET /trajets/T/reservations/'] = 'trajet_reservations';
    final request = (await remote.requests('T')).single.toEntity();
    expect(request.passenger.prenom, isNotEmpty);
    expect(request.montant + request.commission, request.prix, reason: 'net + commission = prix payé');
    expect(request.essaisCode, 0);

    await remote.submitCode('R', '1234');
    expect(backend.last.path, '/reservations/R/code-depart/');
    expect(body(), {'code': '1234'});
    await remote.declareAbsence('R', lat: 6.1, lng: 1.2);
    expect(backend.last.path, '/reservations/R/absent/');
    expect(body(), {'lat': 6.1, 'lng': 1.2});
    await remote.accept('R');
    expect(backend.last.path, '/reservations/R/accepter/');

    backend.routes['GET /moi/economies/'] = 'economies';
    expect((await remote.savings()).toEntity().total, greaterThanOrEqualTo(0));
  });

  test('notifications : liste conservée par le backend, écran à ouvrir', () async {
    final remote = ApiNotificationsRemoteDataSource(api);
    backend.routes['GET /notifications/'] = 'notifications';
    final notification = (await remote.list()).single;
    expect(notification.titre, 'Réservation acceptée');
    expect(notification.lue, isFalse);
    expect(notification.donnees['destinataire'], 'passager');
    expect(notification.donnees['reservation_id'], isNotEmpty);
  });

  test('portefeuille : solde, recharge PayGate, état d’une transaction, historique', () async {
    final remote = ApiWalletRemoteDataSource(api);
    backend.routes['GET /portefeuille/'] = 'portefeuille';
    expect((await remote.balance()).disponible, greaterThanOrEqualTo(0));

    backend.routes['POST /portefeuille/recharger/'] = 'recharge';
    final operation = await remote.recharge(montant: 1000, moyen: MobileMoney.mixx, telephone: '+22890000000');
    expect(body(), {'montant': 1000, 'moyen': 'mixx', 'telephone': '+22890000000'});
    expect(operation.transaction.type, TransactionType.recharge);

    backend.routes['GET /portefeuille/transactions/X/'] = 'transaction';
    expect((await remote.transaction('X')).montant, 1000);
    backend.routes['GET /portefeuille/transactions/'] = 'transactions';
    expect((await remote.transactions()).results, isNotEmpty);
  });

  test('véhicule, note, signalement et appareil push', () async {
    backend.routes['GET /vehicules/'] = 'vehicules';
    final vehicle = (await ApiVehicleRemoteDataSource(api).fetchMine())!;
    expect(vehicle.id, isNotNull);

    await ApiRatingRepository(api).rate(bookingId: 'R', note: 5, comment: ' Top ');
    expect(backend.last.path, '/reservations/R/note/');
    expect(body(), {'note': 5, 'commentaire': 'Top'});

    await ApiReportRepository(api).report(bookingId: 'R', reason: ReportReason.retard, description: '20 min');
    expect(backend.last.path, '/reservations/R/signalement/');
    expect(body(), {'motif': 'Retard important — 20 min'});

    await ApiDevicesRepository(api).registerDevice(token: 'fcm', platform: 'android');
    expect(backend.last.path, '/notifications/appareils/');
    expect(body(), {'jeton': 'fcm', 'plateforme': 'android'});
  });

  test('photo de profil : PATCH /moi/ en multipart, champ photo (contrat C3, F-003)', () async {
    final dir = await Directory.systemTemp.createTemp('kovoit_photo_contrat');
    addTearDown(() => dir.delete(recursive: true));
    final photo = await File('${dir.path}/moi.jpg').writeAsBytes([0xFF, 0xD8, 0xFF, 0xD9]);
    final remote = ApiAuthRemoteDataSource(api);
    backend.routes['PATCH /moi/'] = 'moi_photo';

    final profil = await remote.updatePhoto(photo.path);

    expect(backend.last.method, 'PATCH');
    expect(backend.last.path, '/moi/');
    final form = backend.last.data as FormData;
    expect(form.files.map((f) => f.key), ['photo']);
    expect(form.fields, isEmpty);
    // Décision Q1 révisée : chemin relatif renvoyé par le backend, complété avec l'origine de l'API.
    expect(profil.photo, '/media/photos_profil/moi.jpg');
    expect(profil.toEntity().photoUrl, '${Uri.parse(Env.apiBaseUrl).origin}/media/photos_profil/moi.jpg');

    backend
      ..status = 400
      ..routes['PATCH /moi/'] = 'erreur_photo';
    await expectLater(
      remote.updatePhoto(photo.path),
      throwsA(
        isA<BadRequestApiException>()
            .having((e) => e.code, 'code', 'DONNEES_INVALIDES')
            .having((e) => e.fieldErrors['photo'], 'erreurs.photo', contains('image valide')),
      ),
    );
  });

  group('authentification par e-mail + mot de passe (M-004 T0, F-070 à F-073)', () {
    late ApiAuthRemoteDataSource remote;

    setUp(() => remote = ApiAuthRemoteDataSource(api));

    test('inscription : 201 CODE_ENVOYE, corps du contrat (sans la confirmation)', () async {
      backend
        ..status = 201
        ..routes['POST /auth/inscription/'] = 'auth_code_envoye';

      final code = await remote.register(
        prenom: 'Ama',
        nom: 'Mensah',
        email: 'ama.mensah@exemple.tg',
        telephone: '+22890112233',
        motDePasse: 'Trajet-Lome-26',
        cguAcceptees: true,
      );

      expect(body(), {
        'prenom': 'Ama',
        'nom': 'Mensah',
        'email': 'ama.mensah@exemple.tg',
        'telephone': '+22890112233',
        'mot_de_passe': 'Trajet-Lome-26',
        'cgu_acceptees': true,
      });
      expect(code.toEntity().email, 'ama.mensah@exemple.tg');
      expect(code.toEntity().resendIn, const Duration(seconds: 60));
    });

    test('inscription/verifier puis connexion : SESSION décodée (nouveau_compte)', () async {
      backend.routes['POST /auth/inscription/verifier/'] = 'auth_session_inscription';
      final inscrit = await remote.verifyEmail(email: 'ama.mensah@exemple.tg', code: '123456');
      expect(body(), {'email': 'ama.mensah@exemple.tg', 'code': '123456'});
      expect(inscrit.nouveauCompte, isTrue);
      expect(inscrit.access, 'jeton-acces');
      expect(inscrit.utilisateur.toEntity().profilComplet, isTrue);

      backend.routes['POST /auth/connexion/'] = 'auth_session_connexion';
      final connecte = await remote.login(email: 'ama.mensah@exemple.tg', motDePasse: 'Trajet-Lome-26');
      expect(body(), {'email': 'ama.mensah@exemple.tg', 'mot_de_passe': 'Trajet-Lome-26'});
      expect(connecte.nouveauCompte, isFalse);
      expect(connecte.refresh, 'jeton-rafraichissement');
      expect(connecte.utilisateur.toEntity().email, 'ama.mensah@exemple.tg');
    });

    test('renvoyer-code, oublie, reinitialiser : chemins et corps', () async {
      backend
        ..routes['POST /auth/inscription/renvoyer-code/'] = 'auth_code_envoye'
        ..routes['POST /auth/mot-de-passe/oublie/'] = 'auth_code_envoye'
        ..routes['POST /auth/mot-de-passe/reinitialiser/'] = 'auth_reinitialise';

      expect((await remote.resendVerificationCode('ama.mensah@exemple.tg')).delaiRenvoiS, 60);
      expect(body(), {'email': 'ama.mensah@exemple.tg'});
      expect((await remote.requestPasswordReset('ama.mensah@exemple.tg')).email, 'ama.mensah@exemple.tg');
      expect(body(), {'email': 'ama.mensah@exemple.tg'});
      await remote.resetPassword(email: 'ama.mensah@exemple.tg', code: '123456', motDePasse: 'Nouveau-2026');
      expect(body(), {'email': 'ama.mensah@exemple.tg', 'code': '123456', 'mot_de_passe': 'Nouveau-2026'});

      expect(backend.requests.map((r) => '${r.method} ${r.path}'), [
        'POST /auth/inscription/renvoyer-code/',
        'POST /auth/mot-de-passe/oublie/',
        'POST /auth/mot-de-passe/reinitialiser/',
      ]);
    });

    test('erreurs du contrat : code métier, message de l’API et erreurs par champ', () async {
      Future<ApiException> rejected(int status, String route, String fixture, Future<Object?> Function() call) async {
        backend
          ..status = status
          ..routes[route] = fixture;
        try {
          await call();
        } on ApiException catch (e) {
          return e;
        }
        fail('$route aurait dû échouer');
      }

      Future<Object?> inscrire() => remote.register(
            prenom: 'Ama',
            nom: 'Mensah',
            email: 'ama.mensah@exemple.tg',
            telephone: '+22890112233',
            motDePasse: '12345678',
            cguAcceptees: true,
          );

      final identifiants = await rejected(401, 'POST /auth/connexion/', 'auth_erreur_identifiants',
          () => remote.login(email: 'x@exemple.tg', motDePasse: 'faux'));
      expect(identifiants, isA<UnauthorizedApiException>());
      expect(identifiants.code, 'IDENTIFIANTS_INVALIDES');
      expect(identifiants.message, 'Email ou mot de passe incorrect.');

      final nonVerifie = await rejected(403, 'POST /auth/connexion/', 'auth_erreur_email_non_verifie',
          () => remote.login(email: 'x@exemple.tg', motDePasse: 'bon'));
      expect(nonVerifie, isA<ForbiddenApiException>());
      expect(nonVerifie.code, 'EMAIL_NON_VERIFIE');

      final dejaUtilise = await rejected(409, 'POST /auth/inscription/', 'auth_erreur_email_deja_utilise', inscrire);
      expect(dejaUtilise, isA<ConflictApiException>());
      expect(dejaUtilise.code, 'EMAIL_DEJA_UTILISE');
      expect(dejaUtilise.details['email'], ['Un compte existe déjà avec cette adresse e-mail.']);

      final faible = await rejected(400, 'POST /auth/inscription/', 'auth_erreur_mot_de_passe_faible', inscrire);
      expect(faible.code, 'MOT_DE_PASSE_FAIBLE');
      expect((faible as BadRequestApiException).fieldErrors['mot_de_passe'], 'Ce mot de passe est trop courant.');

      final code = await rejected(400, 'POST /auth/mot-de-passe/reinitialiser/', 'auth_erreur_code_invalide',
          () => remote.resetPassword(email: 'x@exemple.tg', code: '000000', motDePasse: 'Nouveau-2026'));
      expect(code.code, 'CODE_OTP_INVALIDE');
      expect(code.message, 'Code invalide ou expiré.');
    });

    test('les 6 routes auth/… sont publiques (sans refresh) ; plus aucune route auth/otp/ (D-70)', () {
      expect(ApiEndpoints.sansRafraichissement, containsAll([
        '/auth/inscription/',
        '/auth/inscription/verifier/',
        '/auth/inscription/renvoyer-code/',
        '/auth/connexion/',
        '/auth/mot-de-passe/oublie/',
        '/auth/mot-de-passe/reinitialiser/',
      ]));
      expect(ApiEndpoints.sansRafraichissement.where((p) => p.startsWith('/auth/otp/')), isEmpty);
      final source = File('lib/core/constants/api_constants.dart').readAsStringSync();
      expect(source, isNot(contains('/auth/otp/')));
    });
  });

  test('erreur du backend : code métier conservé', () async {
    backend
      ..status = 409
      ..routes['POST /reservations/'] = 'erreur_solde';
    await expectLater(
      ApiBookingRemoteDataSource(api).request(tripId: 'T', pickupPointId: 'P', arrivee: (libelle: '', lat: 0, lng: 0)),
      throwsA(isA<ConflictApiException>().having((e) => e.code, 'code', 'DEJA_RESERVE')),
    );
  });

  test('les fixtures viennent bien du backend (enveloppe { statut, message, reponse })', () {
    for (final file in Directory(
      'test/fixtures/backend',
    ).listSync().whereType<File>().where((f) => f.path.endsWith('.json'))) {
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(json.keys, containsAll(['statut', 'message', 'reponse']), reason: file.path);
    }
  });
}
