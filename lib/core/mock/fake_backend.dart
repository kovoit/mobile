import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/demo_account.dart';
import '../network/api_exception.dart';
import '../storage/token_storage.dart';

/// Backend simulé en mémoire, partagé par toutes les fausses datasources (`Env.useMockApi`).
/// Il manipule le JSON des contrats `docs/api/*.md` pour que `core` ne dépende d'aucune feature.
/// Il reproduit les règles serveur utiles au mobile (statuts KYC, droits du mode conducteur).
class FakeBackend {
  FakeBackend(this._tokenStorage, {this.latency = const Duration(milliseconds: 600)}) {
    _seedDemoAccount();
  }

  final TokenStorage _tokenStorage;
  final Duration latency;

  final Map<int, FakeUserRecord> _users = {};
  final Map<int, Map<String, FakeKycDossier>> _kyc = {};
  final Map<int, Map<String, dynamic>> _vehicles = {};
  int _nextId = 2;

  static const String googleEmail = 'ama.google@gmail.com';

  Future<void> wait() => Future<void>.delayed(latency);

  void _seedDemoAccount() {
    _users[1] = FakeUserRecord(
      password: DemoAccount.password,
      fields: {
        'id': 1,
        'prenom': 'Kodjo',
        'nom': 'Mensah',
        'email': DemoAccount.email,
        'telephone': '+22890123456',
        'telephone_verifie': true,
        'photo': null,
        'mode_actif': 'passager',
        'statut_compte': 'actif',
        'suspendu_jusqu_au': null,
      },
    );
    // Le compte démo a un KYC passager validé : il peut réserver, pas encore publier.
    _kyc[1] = {'passager': FakeKycDossier(statut: 'verifie', pieces: {...kycPieces['passager']!})};
  }

  /// Pièces attendues par type de dossier (voir docs/api/kyc.md).
  static const Map<String, List<String>> kycPieces = {
    'passager': ['photo_profil', 'identite_recto', 'identite_verso', 'selfie'],
    'conducteur': ['permis', 'carte_grise_ou_assurance', 'photo_vehicule'],
  };

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

  bool phoneTaken(String telephone, {int? exceptId}) =>
      _users.values.any((u) => u.fields['telephone'] == telephone && u.fields['id'] != exceptId);

  int createUser({required String? password, required Map<String, dynamic> fields}) {
    final id = _nextId++;
    _users[id] = FakeUserRecord(
      password: password,
      fields: {
        'telephone': null,
        'telephone_verifie': false,
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

  Map<String, dynamic> issueTokens(int id) =>
      {'access': 'mock-access-$id', 'refresh': 'mock-refresh-$id', 'user': userJson(id)};

  // ---------------------------------------------------------------- KYC

  FakeKycDossier kycDossier(int userId, String type) =>
      _kyc.putIfAbsent(userId, () => {}).putIfAbsent(type, () => FakeKycDossier(statut: 'non_verifie', pieces: {}));

  List<Map<String, dynamic>> kycDossiersJson(int userId) => [
        for (final type in kycPieces.keys) kycDossierJson(userId, type),
      ];

  Map<String, dynamic> kycDossierJson(int userId, String type) {
    final dossier = kycDossier(userId, type);
    return {
      'type': type,
      'statut': dossier.statut,
      'motif_rejet': dossier.motifRejet,
      'pieces': [
        for (final piece in kycPieces[type]!) {'type_piece': piece, 'fournie': dossier.pieces.contains(piece)},
      ],
    };
  }

  // ---------------------------------------------------------------- Véhicules

  Map<String, dynamic>? vehicleJson(int userId) => _vehicles[userId];

  void saveVehicle(int userId, Map<String, dynamic> vehicle) =>
      _vehicles[userId] = {...vehicle, 'id': userId, 'statut_verification': 'en_attente'};

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
    final vehicle = _vehicles[id];
    if (vehicle != null && approve) vehicle['statut_verification'] = 'verifie';
  }
}

class FakeUserRecord {
  FakeUserRecord({required this.password, required this.fields});

  /// `null` pour un compte Google.
  final String? password;
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
