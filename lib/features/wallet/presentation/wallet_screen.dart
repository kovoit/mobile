import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/wallet.dart';
import 'wallet_providers.dart';

/// Portefeuille : solde (calculé par le backend), recharge et retrait Flooz / Mixx, historique.
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(walletBalanceProvider);
    final transactions = ref.watch(walletTransactionsProvider);

    return Scaffold(
      appBar: const KovoitAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(walletBalanceProvider);
          ref.invalidate(walletTransactionsProvider);
          await ref.read(walletBalanceProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            const ScreenHeader(title: 'Mon portefeuille', subtitle: 'Rechargé par Flooz ou Mixx. Pas d’espèces.'),
            const SizedBox(height: AppSpacing.lg),
            switch (balance) {
              AsyncValue(:final value?) => _BalanceCard(balance: value),
              AsyncValue(:final error?) => InfoBanner(
                  icon: Icons.wifi_off_rounded,
                  tone: InfoBannerTone.error,
                  title: error is ApiException ? error.message : 'Solde indisponible.',
                ),
              _ => const Center(child: CircularProgressIndicator()),
            },
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: 'Recharger',
                    icon: Icons.add_rounded,
                    onPressed: () => context.push(Routes.walletRecharge()),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: PrimaryButton.outlined(
                    label: 'Retirer',
                    icon: Icons.south_east_rounded,
                    onPressed: () => context.push(Routes.walletWithdraw),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text('Mouvements', style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.xs),
            ...switch (transactions) {
              AsyncValue(:final value?) when value.isEmpty => const [
                  Text('Aucun mouvement pour le moment.', style: AppTextStyles.subtitle),
                ],
              AsyncValue(:final value?) => [for (final t in value) _TransactionTile(transaction: t)],
              AsyncValue(:final error?) => [
                  Text(error is ApiException ? error.message : 'Historique indisponible.', style: AppTextStyles.caption),
                ],
              _ => const [Center(child: CircularProgressIndicator())],
            },
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});

  final WalletBalance balance;

  @override
  Widget build(BuildContext context) {
    return KovoitCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Disponible', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.xxs),
          Text(Formatters.fcfa(balance.disponible), style: AppTextStyles.display),
          if (balance.bloque > 0) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${Formatters.fcfa(balance.bloque)} réservés pour vos demandes en cours',
              style: AppTextStyles.caption,
            ),
          ],
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final WalletTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final sign = t.type == TransactionType.blocage || !t.type.isIncoming ? '−' : '+';
    final moyen = t.moyen == null ? '' : ' · ${t.moyen!.label}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${t.type.label}$moyen', style: AppTextStyles.label),
                Text(Formatters.date(t.createdAt), style: AppTextStyles.caption),
              ],
            ),
          ),
          if (t.status == TransactionStatus.enAttente)
            const Padding(
              padding: EdgeInsets.only(right: AppSpacing.xs),
              child: StatusChip(label: 'En attente', tone: StatusTone.warning),
            ),
          if (t.status == TransactionStatus.echouee)
            const Padding(
              padding: EdgeInsets.only(right: AppSpacing.xs),
              child: StatusChip(label: 'Échouée', tone: StatusTone.error),
            ),
          Text(
            '$sign ${Formatters.fcfa(t.montant)}',
            style: AppTextStyles.label.copyWith(
              color: t.status == TransactionStatus.echouee
                  ? AppColors.textDisabled
                  : sign == '+'
                      ? AppColors.success
                      : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
