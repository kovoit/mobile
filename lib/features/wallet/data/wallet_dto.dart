import 'package:json_annotation/json_annotation.dart';

import '../domain/wallet.dart';

part 'wallet_dto.g.dart';

/// `GET /portefeuille/` (backend : SoldeSerializer).
@JsonSerializable(fieldRename: FieldRename.snake)
class WalletBalanceDto {
  const WalletBalanceDto({required this.total, required this.bloque, required this.disponible});

  factory WalletBalanceDto.fromJson(Map<String, dynamic> json) => _$WalletBalanceDtoFromJson(json);

  final int total;
  final int bloque;
  final int disponible;

  Map<String, dynamic> toJson() => _$WalletBalanceDtoToJson(this);

  WalletBalance toEntity() => WalletBalance(total: total, bloque: bloque, disponible: disponible);
}

/// Mouvement du journal (backend : TransactionSerializer).
@JsonSerializable(fieldRename: FieldRename.snake)
class WalletTransactionDto {
  const WalletTransactionDto({
    required this.id,
    required this.type,
    required this.montant,
    required this.statut,
    required this.creeLe,
    this.moyenPaiement = '',
    this.referenceExterne = '',
    this.telephone = '',
  });

  factory WalletTransactionDto.fromJson(Map<String, dynamic> json) => _$WalletTransactionDtoFromJson(json);

  final String id;
  final String type;
  final int montant;
  final String statut;
  final DateTime creeLe;
  final String moyenPaiement;
  final String referenceExterne;
  final String telephone;

  Map<String, dynamic> toJson() => _$WalletTransactionDtoToJson(this);

  WalletTransaction toEntity() => WalletTransaction(
        id: id,
        type: TransactionType.fromApi(type),
        montant: montant,
        status: TransactionStatus.fromApi(statut),
        createdAt: creeLe,
        moyen: MobileMoney.fromApi(moyenPaiement),
        reference: referenceExterne,
        telephone: telephone,
      );
}

/// Réponse de `POST /portefeuille/recharger/` et `/retirer/` (201 validée, 202 en attente).
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class WalletOperationDto {
  const WalletOperationDto({required this.transaction, required this.solde});

  factory WalletOperationDto.fromJson(Map<String, dynamic> json) => _$WalletOperationDtoFromJson(json);

  final WalletTransactionDto transaction;
  final WalletBalanceDto solde;

  Map<String, dynamic> toJson() => _$WalletOperationDtoToJson(this);

  WalletOperation toEntity({String message = ''}) =>
      WalletOperation(transaction: transaction.toEntity(), balance: solde.toEntity(), message: message);
}
