/// Portefeuille Kovoit : rechargé par Flooz ou Mixx via PayGate, sans espèces (décision du
/// 22/10/2026). Le solde est toujours calculé par le backend, jamais par l'application.
library;

enum MobileMoney {
  flooz('flooz', 'Flooz'),
  mixx('mixx', 'Mixx');

  const MobileMoney(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static MobileMoney? fromApi(String? value) => values.where((m) => m.apiValue == value).firstOrNull;
}

/// `validee` : prise en compte dans le solde ; `en_attente` : le client doit valider sur son
/// téléphone (recharge) ou Kovoit doit verser (retrait) ; `echouee` : rien n'a été débité.
enum TransactionStatus {
  validee('validee'),
  enAttente('en_attente'),
  echouee('echouee');

  const TransactionStatus(this.apiValue);

  final String apiValue;

  static TransactionStatus fromApi(String? value) =>
      values.firstWhere((s) => s.apiValue == value, orElse: () => TransactionStatus.enAttente);
}

enum TransactionType {
  recharge('recharge', 'Recharge'),
  blocage('blocage', 'Montant réservé'),
  deblocage('deblocage', 'Montant libéré'),
  debit('debit', 'Trajet payé'),
  credit('credit', 'Trajet encaissé'),
  retrait('retrait', 'Retrait'),
  remboursement('remboursement', 'Remboursement');

  const TransactionType(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static TransactionType fromApi(String? value) =>
      values.firstWhere((t) => t.apiValue == value, orElse: () => TransactionType.recharge);

  /// Sens pour l'affichage (+ / −) ; les blocages ne changent pas le solde total.
  bool get isIncoming => this == recharge || this == credit || this == remboursement || this == deblocage;
}

class WalletBalance {
  const WalletBalance({required this.total, required this.bloque, required this.disponible});

  final int total;

  /// Réservé pour des demandes de place en cours.
  final int bloque;
  final int disponible;
}

class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.type,
    required this.montant,
    required this.status,
    required this.createdAt,
    this.moyen,
    this.reference = '',
    this.telephone = '',
  });

  final String id;
  final TransactionType type;
  final int montant;
  final TransactionStatus status;
  final DateTime createdAt;
  final MobileMoney? moyen;
  final String reference;
  final String telephone;
}

/// Résultat d'une recharge ou d'un retrait : l'opération et le solde à jour.
class WalletOperation {
  const WalletOperation({required this.transaction, required this.balance, this.message = ''});

  final WalletTransaction transaction;
  final WalletBalance balance;

  /// Consigne du backend (« Validez le paiement sur votre téléphone… »).
  final String message;
}
