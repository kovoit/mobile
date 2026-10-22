import '../../../core/constants/api_constants.dart';
import '../../../core/mock/fake_wallet.dart';
import '../../../core/network/api_service.dart';
import '../domain/wallet.dart';
import 'wallet_dto.dart';

abstract interface class WalletRemoteDataSource {
  Future<WalletBalance> balance();

  Future<Paginated<WalletTransaction>> transactions({int page = 1});

  /// Recharge Flooz / Mixx. En attente tant que le client n'a pas validé sur son téléphone.
  Future<WalletOperation> recharge({required int montant, required MobileMoney moyen, String telephone = ''});

  Future<WalletOperation> withdraw({required int montant, required MobileMoney moyen, String telephone = ''});

  /// État d'une opération : une recharge en attente est revérifiée par le backend auprès de PayGate.
  Future<WalletTransaction> transaction(String id);
}

class ApiWalletRemoteDataSource implements WalletRemoteDataSource {
  const ApiWalletRemoteDataSource(this._api);

  final ApiService _api;

  static WalletTransaction _transaction(Map<String, dynamic> json) => WalletTransactionDto.fromJson(json).toEntity();

  @override
  Future<WalletBalance> balance() =>
      _api.get(ApiEndpoints.portefeuille, parse: (json) => WalletBalanceDto.fromJson(ApiService.asMap(json)).toEntity());

  @override
  Future<Paginated<WalletTransaction>> transactions({int page = 1}) =>
      _api.getPage(ApiEndpoints.portefeuilleTransactions, page: page, item: _transaction);

  Future<WalletOperation> _operation(String path, int montant, MobileMoney moyen, String telephone) async {
    final response = await _api.send(
      path,
      method: 'POST',
      body: {'montant': montant, 'moyen': moyen.apiValue, if (telephone.isNotEmpty) 'telephone': telephone},
      parse: (json) => WalletOperationDto.fromJson(ApiService.asMap(json)),
    );
    return response.data.toEntity(message: response.message);
  }

  @override
  Future<WalletOperation> recharge({required int montant, required MobileMoney moyen, String telephone = ''}) =>
      _operation(ApiEndpoints.portefeuilleRecharger, montant, moyen, telephone);

  @override
  Future<WalletOperation> withdraw({required int montant, required MobileMoney moyen, String telephone = ''}) =>
      _operation(ApiEndpoints.portefeuilleRetirer, montant, moyen, telephone);

  @override
  Future<WalletTransaction> transaction(String id) =>
      _api.get(ApiEndpoints.portefeuilleTransaction(id), parse: (json) => _transaction(ApiService.asMap(json)));
}

/// Fausse API (`Env.useMockApi`) : PayGate simulé (paiement validé au second contrôle).
class FakeWalletRemoteDataSource implements WalletRemoteDataSource {
  FakeWalletRemoteDataSource(this._wallet);

  final FakeWallet _wallet;

  @override
  Future<WalletBalance> balance() async => WalletBalanceDto.fromJson(await _wallet.balance()).toEntity();

  @override
  Future<Paginated<WalletTransaction>> transactions({int page = 1}) async {
    final items = await _wallet.transactions();
    return Paginated(
      count: items.length,
      results: [for (final json in items) WalletTransactionDto.fromJson(json).toEntity()],
    );
  }

  @override
  Future<WalletOperation> recharge({required int montant, required MobileMoney moyen, String telephone = ''}) async {
    final result = await _wallet.recharge(montant: montant, moyen: moyen.apiValue, telephone: telephone);
    return WalletOperationDto.fromJson(result.json).toEntity(message: result.message);
  }

  @override
  Future<WalletOperation> withdraw({required int montant, required MobileMoney moyen, String telephone = ''}) async {
    final result = await _wallet.withdraw(montant: montant, moyen: moyen.apiValue, telephone: telephone);
    return WalletOperationDto.fromJson(result.json).toEntity(message: result.message);
  }

  @override
  Future<WalletTransaction> transaction(String id) async =>
      WalletTransactionDto.fromJson(await _wallet.transaction(id)).toEntity();
}
