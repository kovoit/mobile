import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/demo_account.dart';
import '../network/api_exception.dart';
import '../storage/token_storage.dart';

/// Backend simulé en mémoire, partagé par toutes les fausses datasources (`Env.useMockApi`).
/// Il manipule le JSON des contrats `docs/api/*.md` pour que `core` ne dépende d'aucune feature.
/// Il reproduit les règles serveur utiles au mobile (statuts KYC, droits du mode conducteur).
class FakeBackend {
  FakeBackend(
    this._tokenStorage, {
    this.latency = const Duration(milliseconds: 600),
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now {
    _seedDemoAccount();
  }

  final TokenStorage _tokenStorage;
  final Duration latency;

  /// Horloge « serveur » (injectable pour des tests déterministes).
  final DateTime Function() clock;

  /// Réservations simulées des passagers, par id `resa-…` (voir fake_bookings.dart).
  final Map<String, Map<String, dynamic>> bookings = {};
  int nextBookingId = 501;

  /// Trajets publiés (ids `trajet-pub-…`) et demandes reçues par les conducteurs (fake_driver.dart).
  final Map<String, Map<String, dynamic>> driverTrips = {};
  int nextDriverTripId = 9001;
  int nextDriverRequestId = 801;

  /// Crédits des conducteurs : lignes `{date, trajet_id, depart_le, depart, arrivee, montant}`.
  final Map<int, List<Map<String, dynamic>>> savings = {};

  /// Notes déjà données : clés `reservationId:auteurId`.
  final Set<String> ratings = {};

  /// Signalements ouverts : clés `reservationId:auteurId` → motif.
  final Map<String, String> reports = {};

  /// Appareils enregistrés pour le push : token → utilisateur.
  final Map<String, int> devices = {};

  /// Notifications de l'utilisateur de démo, plus anciennes d'abord (fake_notifications.dart).
  final List<Map<String, dynamic>> notifications = [];
  int _nextNotificationId = 1;

  /// Enregistre une notification comme le backend (`notifier`) : titre, message, écran à ouvrir.
  void notify(String titre, String message, Map<String, String> donnees) => notifications.add({
        'id': 'notif-${_nextNotificationId++}',
        'titre': titre,
        'message': message,
        'donnees': donnees,
        'lue_le': null,
        'cree_le': clock().toUtc().toIso8601String(),
      });

  /// Journal du portefeuille par utilisateur, plus récents d'abord (voir fake_wallet.dart).
  final Map<int, List<Map<String, dynamic>>> wallets = {};

  final Map<int, FakeUserRecord> _users = {};
  final Map<int, Map<String, FakeKycDossier>> _kyc = {};
  final Map<int, Map<String, dynamic>> _vehicles = {};
  int _nextId = 2;

  Future<void> wait() => Future<void>.delayed(latency);

  void _seedDemoAccount() {
    // Compte de démo : 2 000 F déjà rechargés, pour réserver sans passer par Mobile Money
    wallets[1] = [
      {
        'id': 'tx-demo',
        'type': 'recharge',
        'montant': 2000,
        'moyen_paiement': 'flooz',
        'reservation': null,
        'reference_externe': 'PG-SIM-DEMO',
        'statut': 'validee',
        'telephone': '+22890123456',
        'cree_le': '2026-10-01T08:00:00Z',
      },
    ];
    _users[1] = FakeUserRecord(
      fields: {
        'id': 1,
        'prenom': 'Kodjo',
        'nom': 'Mensah',
        'email': DemoAccount.email,
        'telephone': '+22890123456',
        'photo': null,
        'mode_actif': 'passager',
        'statut_compte': 'actif',
        'suspendu_jusqu_au': null,
      },
    );
    // Le compte démo a un KYC passager validé : il peut réserver, pas encore publier.
    _kyc[1] = {'passager': FakeKycDossier(statut: 'verifie', pieces: {...kycPieces['passager']!})};

    // Conducteur de démo : tous les droits, véhicule déclaré, en mode conducteur.
    _users[2] = FakeUserRecord(
      fields: {
        'id': 2,
        'prenom': 'Yao',
        'nom': 'Agbodjan',
        'email': DemoAccount.driverEmail,
        'telephone': '+22891000002',
        'photo': null,
        'mode_actif': 'conducteur',
        'statut_compte': 'actif',
        'suspendu_jusqu_au': null,
      },
    );
    _kyc[2] = {
      'passager': FakeKycDossier(statut: 'verifie', pieces: {...kycPieces['passager']!}),
      'conducteur': FakeKycDossier(statut: 'verifie', pieces: {...kycPieces['conducteur']!}),
    };
    _vehicles[2] = {
      'id': 'v-2',
      'type_vehicule': 'voiture',
      'marque': 'Toyota',
      'modele': 'Yaris',
      'couleur': 'Gris',
      'immatriculation': 'TG 4827 AU',
      'nb_places': 5,
      'photo': null,
    };
    // Économies déjà réalisées ce mois-ci (maquette : 18 500 FCFA, 24 places partagées).
    final now = clock().toUtc();
    // Conducteur de démo : un mois déjà bien rempli (crédits au format de /moi/economies/)
    final debutDuMois = DateTime.utc(now.year, now.month).toIso8601String();
    savings[2] = [
      {
        'date': debutDuMois,
        'trajet_id': 'trajet-demo-1',
        'depart_le': debutDuMois,
        'depart': 'Carrefour Franciscain',
        'arrivee': 'Université de Lomé · Entrée sud',
        'montant': 18500,
      },
    ];
    _nextId = 3;
  }

  /// Dossiers complets (voir docs/api/kyc.md) : le conducteur fournit aussi identité et selfie,
  /// et la carte grise OU l'assurance.
  static const Map<String, List<String>> kycPieces = {
    'passager': ['identite', 'selfie'],
    'conducteur': ['identite', 'selfie', 'permis', 'carte_grise', 'photo_vehicule'],
  };

  static const Set<String> _kycVehicleDocuments = {'carte_grise', 'assurance'};

  static Set<String> kycAllowedPieces(String type) =>
      {...kycPieces[type]!.where((p) => !_kycVehicleDocuments.contains(p)), if (type == 'conducteur') ..._kycVehicleDocuments};

  /// Comme `pieces_manquantes` du backend.
  static List<String> kycMissingPieces(String type, Set<String> pieces) {
    final required = kycAllowedPieces(type).difference(_kycVehicleDocuments);
    return [
      ...required.difference(pieces),
      if (type == 'conducteur' && pieces.intersection(_kycVehicleDocuments).isEmpty) 'carte_grise_ou_assurance',
    ];
  }

  // ---------------------------------------------------------------- Utilisateurs

  /// Objet `user` complet, statuts KYC et véhicule calculés comme le ferait le serveur.
  Map<String, dynamic> userJson(int id) {
    final record = _users[id]!;
    return {
      ...record.fields,
      'kyc_passager': _kyc[id]?['passager']?.statut ?? 'non_verifie',
      'kyc_conducteur': _kyc[id]?['conducteur']?.statut ?? 'non_verifie',
      'vehicule_declare': _vehicles.containsKey(id),
    };
  }

  FakeUserRecord? userByEmail(String email) =>
      _users.values.where((u) => u.fields['email'] == email.trim().toLowerCase()).firstOrNull;

  /// Compte supprimé (anonymisé côté serveur) : il ne peut plus se connecter.
  void deleteUser(int id) => _users.remove(id);

  bool phoneTaken(String telephone, {int? exceptId}) =>
      _users.values.any((u) => u.fields['telephone'] == telephone && u.fields['id'] != exceptId);

  /// Crée un compte (premier code valide pour une adresse inconnue). Profil à compléter.
  int createUser({required Map<String, dynamic> fields}) {
    final id = _nextId++;
    _users[id] = FakeUserRecord(
      fields: {
        'prenom': '',
        'nom': '',
        'telephone': null,
        'cgu_acceptees': false,
        'photo': null,
        'mode_actif': 'passager',
        'statut_compte': 'actif',
        'suspendu_jusqu_au': null,
        ...fields,
        'id': id,
      },
    );
    return id;
  }

  void updateUser(int id, Map<String, dynamic> changes) => _users[id]!.fields.addAll(changes);

  /// Identifie l'appelant à partir du jeton stocké (le vrai backend lit le header Authorization).
  Future<int> currentUserId() async {
    final token = await _tokenStorage.readAccessToken();
    final id = int.tryParse(token?.replaceFirst('mock-access-', '') ?? '');
    if (id == null || !_users.containsKey(id)) {
      throw const UnauthorizedApiException('Session expirée, veuillez vous reconnecter.');
    }
    return id;
  }

  /// Profil au format du backend (`ProfilSerializer` : `GET /moi/`).
  Map<String, dynamic> profilJson(int id) {
    final user = userJson(id);
    bool filled(String key) => (user[key] as String? ?? '').isNotEmpty;
    return {
      ...user,
      'id': '$id',
      'telephone': user['telephone'] ?? '',
      'email_verifie': true,
      'profil_complet': filled('prenom') && filled('nom') && filled('telephone'),
      // Comptes de démo : CGU déjà acceptées ; un nouveau compte les accepte avec son profil
      'cgu_acceptees': user['cgu_acceptees'] ?? true,
      'kyc': {'passager': user['kyc_passager'], 'conducteur': user['kyc_conducteur']},
      'etat': {
        'mode_conducteur': {'vehicule_declare': user['vehicule_declare']},
      },
    };
  }

  /// Réponse de `POST /auth/otp/verifier/`.
  Map<String, dynamic> issueTokens(int id, {bool nouveauCompte = false}) => {
        'access': 'mock-access-$id',
        'refresh': 'mock-refresh-$id',
        'nouveau_compte': nouveauCompte,
        'utilisateur': profilJson(id),
      };

  // ---------------------------------------------------------------- KYC

  FakeKycDossier kycDossier(int userId, String type) =>
      _kyc.putIfAbsent(userId, () => {}).putIfAbsent(type, () => FakeKycDossier(statut: 'non_verifie', pieces: {}));

  List<Map<String, dynamic>> kycDossiersJson(int userId) => [
        for (final type in kycPieces.keys) kycDossierJson(userId, type),
      ];

  Map<String, dynamic> kycDossierJson(int userId, String type) {
    final dossier = kycDossier(userId, type);
    return {
      'id': 'dossier-$userId-$type',
      'type': type,
      'statut': dossier.statut,
      'motif_rejet': dossier.motifRejet ?? '',
      'pieces': [for (final piece in dossier.pieces) {'type_piece': piece}],
      'pieces_manquantes': kycMissingPieces(type, dossier.pieces),
    };
  }

  // ---------------------------------------------------------------- Véhicules

  Map<String, dynamic>? vehicleJson(int userId) => _vehicles[userId];

  void saveVehicle(int userId, Map<String, dynamic> vehicle) =>
      _vehicles[userId] = {...vehicle, 'id': 'v-$userId', 'photo': null};

  // ---------------------------------------------------------------- Outils de démo

  /// Simule la décision de l'administrateur sur les dossiers en attente (bouton dev du Profil).
  Future<void> simulateAdminDecision({bool approve = true}) async {
    final id = await currentUserId();
    for (final dossier in _kyc[id]?.values ?? const <FakeKycDossier>[]) {
      if (dossier.statut != 'en_attente') continue;
      dossier.statut = approve ? 'verifie' : 'rejete';
      dossier.motifRejet = approve ? null : 'Photo de la pièce illisible. Merci de la reprendre en pleine lumière.';
      if (!approve) dossier.pieces.clear();
    }
  }
}

class FakeUserRecord {
  FakeUserRecord({required this.fields});

  final Map<String, dynamic> fields;

  int get id => fields['id'] as int;
}

class FakeKycDossier {
  FakeKycDossier({required this.statut, required this.pieces, this.motifRejet});

  String statut;
  String? motifRejet;
  final Set<String> pieces;
}

final fakeBackendProvider = Provider<FakeBackend>((ref) => FakeBackend(ref.watch(tokenStorageProvider)));
