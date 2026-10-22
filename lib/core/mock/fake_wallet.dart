import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_exception.dart';
import 'fake_backend.dart';

final fakeWalletProvider = Provider<FakeWallet>((ref) => FakeWallet(ref.watch(fakeBackendProvider)));

/// Portefeuille **serveur** simulé (`Env.useMockApi`), mêmes règles que le backend :
/// journal en ajout seul, solde recalculé, seules les lignes validées comptent (un retrait en
/// attente est déjà retenu). PayGate est simulé : une recharge est validée au second contrôle.
class FakeWallet {
  FakeWallet(this._backend);

  final FakeBackend _backend;

  static const int rechargeMin = 500;
  static const int retraitMin = 500;

  /// Contrôles avant qu'une recharge simulée soit validée (le client « valide sur son téléphone »).
  static const int controlesAvantValidation = 2;

  int _nextId = 1;
  final Map<String, int> _controles = {};

  List<Map<String, dynamic>> _ledger(int userId) => _backend.wallets.putIfAbsent(userId, () => []);

  static bool _compte(Map<String, dynamic> t) =>
      t['statut'] == 'validee' || (t['type'] == 'retrait' && t['statut'] == 'en_attente');

  /// Solde au format `SoldeSerializer`.
  Map<String, int> balanceOf(int userId) {
    int sum(String type) => _ledger(userId)
        .where((t) => t['type'] == type && _compte(t))
        .fold(0, (total, t) => total + (t['montant'] as int));
    final total = sum('recharge') + sum('credit') + sum('remboursement') - sum('debit') - sum('retrait');
    final bloque = sum('blocage') - sum('deblocage');
    return {'total': total, 'bloque': bloque, 'disponible': total - bloque};
  }

  Map<String, dynamic> write(
    int userId,
    String type,
    int montant, {
    String? reservationId,
    String statut = 'validee',
    String moyen = '',
    String telephone = '',
    String reference = '',
  }) {
    final ligne = {
      'id': 'tx-${_nextId++}',
      'type': type,
      'montant': montant,
      'moyen_paiement': moyen,
      'reservation': reservationId,
      'reference_externe': reference,
      'statut': statut,
      'telephone': telephone,
      'cree_le': _backend.clock().toUtc().toIso8601String(),
    };
    if (montant > 0) _ledger(userId).insert(0, ligne);
    return ligne;
  }

  /// Montant encore bloqué pour une réservation.
  int blockedFor(int userId, String reservationId) {
    int sum(String type) => _ledger(userId)
        .where((t) => t['type'] == type && t['reservation'] == reservationId)
        .fold(0, (total, t) => total + (t['montant'] as int));
    return sum('blocage') - sum('deblocage');
  }

  // ------------------------------------------------------------------ API

  Future<Map<String, int>> balance() async {
    await _backend.wait();
    return balanceOf(await _backend.currentUserId());
  }

  Future<List<Map<String, dynamic>>> transactions() async {
    await _backend.wait();
    return List.of(_ledger(await _backend.currentUserId()));
  }

  String _phone(int userId, String telephone) {
    final numero = telephone.trim().isNotEmpty ? telephone.trim() : (_backend.userJson(userId)['telephone'] as String? ?? '');
    if (numero.isEmpty) {
      throw const BadRequestApiException('Indiquez le numéro Mobile Money.', code: 'TELEPHONE_REQUIS');
    }
    return numero;
  }

  Future<({Map<String, dynamic> json, String message})> recharge({
    required int montant,
    required String moyen,
    String telephone = '',
  }) async {
    await _backend.wait();
    final userId = await _backend.currentUserId();
    if (montant < rechargeMin) {
      throw const BadRequestApiException('Recharge minimum : $rechargeMin F CFA.', code: 'DONNEES_INVALIDES');
    }
    final ligne = write(userId, 'recharge', montant,
        statut: 'en_attente', moyen: moyen, telephone: _phone(userId, telephone), reference: 'PG-SIM-${_nextId + 1000}');
    _controles[ligne['id'] as String] = 0;
    return (
      json: {'transaction': ligne, 'solde': balanceOf(userId)},
      message: "Validez le paiement sur votre téléphone pour terminer l'opération.",
    );
  }

  Future<({Map<String, dynamic> json, String message})> withdraw({
    required int montant,
    required String moyen,
    String telephone = '',
  }) async {
    await _backend.wait();
    final userId = await _backend.currentUserId();
    if (montant < retraitMin) {
      throw const BadRequestApiException('Retrait minimum : $retraitMin F CFA.', code: 'DONNEES_INVALIDES');
    }
    if (balanceOf(userId)['disponible']! < montant) {
      throw const ConflictApiException('Solde disponible insuffisant pour ce retrait.', code: 'SOLDE_INSUFFISANT');
    }
    final ligne = write(userId, 'retrait', montant, statut: 'en_attente', moyen: moyen, telephone: _phone(userId, telephone));
    return (
      json: {'transaction': ligne, 'solde': balanceOf(userId)},
      message: 'Retrait enregistré : Kovoit effectue le versement sur votre compte Mobile Money.',
    );
  }

  /// `GET /portefeuille/transactions/{id}/` : la recharge en attente est « revérifiée ».
  Future<Map<String, dynamic>> transaction(String id) async {
    await _backend.wait();
    final userId = await _backend.currentUserId();
    final ligne = _ledger(userId).where((t) => t['id'] == id).firstOrNull;
    if (ligne == null) throw const NotFoundApiException('Ressource introuvable.');
    if (ligne['type'] == 'recharge' && ligne['statut'] == 'en_attente') {
      final controles = (_controles[id] ?? 0) + 1;
      _controles[id] = controles;
      if (controles >= controlesAvantValidation) ligne['statut'] = 'validee';
    }
    return Map.of(ligne);
  }

  /// Complément à recharger avant de réserver [montant] (0 si le solde suffit).
  int complementFor(int userId, int montant) => math.max(montant - balanceOf(userId)['disponible']!, 0);
}
