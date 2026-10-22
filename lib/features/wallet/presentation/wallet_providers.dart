import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/mock/fake_wallet.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_service.dart';
import '../data/wallet_remote_data_source.dart';
import '../domain/wallet.dart';

final walletRemoteDataSourceProvider = Provider<WalletRemoteDataSource>((ref) {
  if (Env.useMockApi) return FakeWalletRemoteDataSource(ref.watch(fakeWalletProvider));
  return ApiWalletRemoteDataSource(ref.watch(apiServiceProvider));
});

final walletBalanceProvider = FutureProvider.autoDispose<WalletBalance>(
  (ref) => ref.watch(walletRemoteDataSourceProvider).balance(),
);

/// Derniers mouvements (première page, plus récents d'abord).
final walletTransactionsProvider = FutureProvider.autoDispose<List<WalletTransaction>>(
  (ref) async => (await ref.watch(walletRemoteDataSourceProvider).transactions()).results,
);

/// Intervalle entre deux vérifications d'un paiement en attente (remplacé dans les tests).
final paymentPollIntervalProvider = Provider<Duration>((ref) => const Duration(seconds: 3));

/// Nombre maximal de vérifications avant de laisser le serveur conclure seul (~5 min).
const int maxPaymentChecks = 100;

enum OperationKind { recharge, withdraw }

/// Étapes d'une recharge ou d'un retrait vues par l'utilisateur.
sealed class OperationState {
  const OperationState();
}

class OperationIdle extends OperationState {
  const OperationIdle();
}

class OperationSubmitting extends OperationState {
  const OperationSubmitting();
}

/// Recharge : le client valide sur son téléphone. Retrait : Kovoit doit verser.
class OperationPending extends OperationState {
  const OperationPending(this.transaction, this.message, {this.stillWaiting = false});

  final WalletTransaction transaction;
  final String message;

  /// Plus de vérification automatique : le solde se mettra à jour dès la confirmation.
  final bool stillWaiting;
}

class OperationDone extends OperationState {
  const OperationDone(this.transaction);

  final WalletTransaction transaction;
  bool get succeeded => transaction.status == TransactionStatus.validee;
}

class OperationError extends OperationState {
  const OperationError(this.message);

  final String message;
}

/// Recharge ou retrait, puis suivi de la confirmation Mobile Money (le backend revérifie
/// le paiement auprès de PayGate à chaque interrogation).
class WalletOperationController extends Notifier<OperationState> {
  WalletOperationController(this.kind);

  final OperationKind kind;

  WalletRemoteDataSource get _remote => ref.read(walletRemoteDataSourceProvider);

  @override
  OperationState build() => const OperationIdle();

  Future<void> submit({required int montant, required MobileMoney moyen, required String telephone}) async {
    state = const OperationSubmitting();
    try {
      final operation = kind == OperationKind.recharge
          ? await _remote.recharge(montant: montant, moyen: moyen, telephone: telephone)
          : await _remote.withdraw(montant: montant, moyen: moyen, telephone: telephone);
      _refreshWallet();
      final transaction = operation.transaction;
      if (transaction.status != TransactionStatus.enAttente) {
        state = OperationDone(transaction);
      } else {
        state = OperationPending(transaction, operation.message);
        // Un retrait en attente est versé par Kovoit : rien à suivre côté client.
        if (kind == OperationKind.recharge) await _follow(transaction, operation.message);
      }
    } on ApiException catch (e) {
      state = OperationError(e.message);
    }
  }

  Future<void> _follow(WalletTransaction transaction, String message) async {
    final interval = ref.read(paymentPollIntervalProvider);
    for (var i = 0; i < maxPaymentChecks; i++) {
      await Future<void>.delayed(interval);
      if (!ref.mounted) return;
      try {
        final current = await _remote.transaction(transaction.id);
        if (!ref.mounted) return;
        if (current.status != TransactionStatus.enAttente) {
          state = OperationDone(current);
          _refreshWallet();
          return;
        }
      } on ApiException {
        // Réseau instable : la vérification suivante réessaiera.
      }
    }
    if (ref.mounted) state = OperationPending(transaction, message, stillWaiting: true);
  }

  void _refreshWallet() {
    ref.invalidate(walletBalanceProvider);
    ref.invalidate(walletTransactionsProvider);
  }

  void reset() => state = const OperationIdle();
}

final walletOperationProvider =
    NotifierProvider.autoDispose.family<WalletOperationController, OperationState, OperationKind>(
  WalletOperationController.new,
);
