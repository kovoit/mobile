// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WalletBalanceDto _$WalletBalanceDtoFromJson(Map<String, dynamic> json) =>
    WalletBalanceDto(
      total: (json['total'] as num).toInt(),
      bloque: (json['bloque'] as num).toInt(),
      disponible: (json['disponible'] as num).toInt(),
    );

Map<String, dynamic> _$WalletBalanceDtoToJson(WalletBalanceDto instance) =>
    <String, dynamic>{
      'total': instance.total,
      'bloque': instance.bloque,
      'disponible': instance.disponible,
    };

WalletTransactionDto _$WalletTransactionDtoFromJson(
  Map<String, dynamic> json,
) => WalletTransactionDto(
  id: json['id'] as String,
  type: json['type'] as String,
  montant: (json['montant'] as num).toInt(),
  statut: json['statut'] as String,
  creeLe: DateTime.parse(json['cree_le'] as String),
  moyenPaiement: json['moyen_paiement'] as String? ?? '',
  referenceExterne: json['reference_externe'] as String? ?? '',
  telephone: json['telephone'] as String? ?? '',
);

Map<String, dynamic> _$WalletTransactionDtoToJson(
  WalletTransactionDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'montant': instance.montant,
  'statut': instance.statut,
  'cree_le': instance.creeLe.toIso8601String(),
  'moyen_paiement': instance.moyenPaiement,
  'reference_externe': instance.referenceExterne,
  'telephone': instance.telephone,
};

WalletOperationDto _$WalletOperationDtoFromJson(Map<String, dynamic> json) =>
    WalletOperationDto(
      transaction: WalletTransactionDto.fromJson(
        json['transaction'] as Map<String, dynamic>,
      ),
      solde: WalletBalanceDto.fromJson(json['solde'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$WalletOperationDtoToJson(WalletOperationDto instance) =>
    <String, dynamic>{
      'transaction': instance.transaction.toJson(),
      'solde': instance.solde.toJson(),
    };
