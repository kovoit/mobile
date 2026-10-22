import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/presentation/providers/session_controller.dart';
import '../domain/wallet.dart';
import 'wallet_providers.dart';

/// Recharge (ou retrait) par Flooz / Mixx. Une recharge PayGate se valide sur le téléphone du
/// client ; l'écran suit la confirmation et renvoie `true` (pop) une fois le solde crédité.
class WalletOperationScreen extends ConsumerStatefulWidget {
  const WalletOperationScreen({super.key, required this.kind, this.initialAmount});

  final OperationKind kind;

  /// Montant proposé (ex. complément à recharger avant une réservation).
  final int? initialAmount;

  @override
  ConsumerState<WalletOperationScreen> createState() => _WalletOperationScreenState();
}

class _WalletOperationScreenState extends ConsumerState<WalletOperationScreen> {
  late final TextEditingController _amount =
      TextEditingController(text: widget.initialAmount == null ? '' : '${widget.initialAmount}');
  late final TextEditingController _phone =
      TextEditingController(text: ref.read(sessionControllerProvider).value?.telephone ?? '');
  MobileMoney _moyen = MobileMoney.flooz;
  String? _amountError;

  bool get _isRecharge => widget.kind == OperationKind.recharge;

  @override
  void dispose() {
    _amount.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _submit() {
    final montant = int.tryParse(_amount.text.trim());
    if (montant == null || montant <= 0) {
      setState(() => _amountError = 'Indiquez un montant en F CFA.');
      return;
    }
    setState(() => _amountError = null);
    ref.read(walletOperationProvider(widget.kind).notifier).submit(
          montant: montant,
          moyen: _moyen,
          telephone: _phone.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(walletOperationProvider(widget.kind));
    final busy = state is OperationSubmitting || (state is OperationPending && !state.stillWaiting && _isRecharge);

    return Scaffold(
      appBar: const KovoitAppBar(),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          ScreenHeader(
            title: _isRecharge ? 'Recharger mon portefeuille' : 'Retirer mes gains',
            subtitle: _isRecharge
                ? 'Paiement Flooz ou Mixx sécurisé par PayGate.'
                : 'Versement sur votre compte Flooz ou Mixx.',
          ),
          const SizedBox(height: AppSpacing.lg),
          KovoitTextField(
            label: 'Montant (F CFA)',
            controller: _amount,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            errorText: _amountError,
            enabled: !busy,
          ),
          const SizedBox(height: AppSpacing.md),
          SegmentedToggle<MobileMoney>(
            selected: _moyen,
            onChanged: busy ? (_) {} : (moyen) => setState(() => _moyen = moyen),
            options: const [
              SegmentedOption(value: MobileMoney.flooz, label: 'Flooz'),
              SegmentedOption(value: MobileMoney.mixx, label: 'Mixx'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          KovoitTextField(
            label: 'Numéro Mobile Money',
            hint: '+228 90 00 00 00',
            controller: _phone,
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_android_rounded,
            enabled: !busy,
          ),
          const SizedBox(height: AppSpacing.lg),
          ..._status(context, state),
          const SizedBox(height: AppSpacing.md),
          if (state is! OperationDone && !(state is OperationPending && !_isRecharge))
            PrimaryButton(
              label: _isRecharge ? 'Payer' : 'Demander le retrait',
              isLoading: busy,
              onPressed: busy ? null : _submit,
            ),
        ],
      ),
    );
  }

  List<Widget> _status(BuildContext context, OperationState state) => switch (state) {
        OperationPending(:final transaction, :final message, :final stillWaiting) => [
            InfoBanner(
              icon: _isRecharge ? Icons.phone_iphone_rounded : Icons.schedule_rounded,
              tone: InfoBannerTone.accent,
              title: message.isNotEmpty ? message : 'Opération en attente de confirmation.',
              subtitle: stillWaiting
                  ? 'Toujours en attente : votre solde sera crédité dès la confirmation.'
                  : '${Formatters.fcfa(transaction.montant)} · ${transaction.moyen?.label ?? ''}',
            ),
            if (_isRecharge && !stillWaiting) ...[
              const SizedBox(height: AppSpacing.md),
              const Center(child: CircularProgressIndicator()),
            ],
            if (!_isRecharge || stillWaiting) ...[
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(label: 'Continuer', onPressed: () => context.pop(!_isRecharge)),
            ],
          ],
        OperationDone(:final transaction, :final succeeded) => [
            InfoBanner(
              icon: succeeded ? Icons.check_circle_rounded : Icons.error_outline_rounded,
              tone: succeeded ? InfoBannerTone.success : InfoBannerTone.error,
              title: succeeded
                  ? '${Formatters.fcfa(transaction.montant)} ${_isRecharge ? 'ajoutés à votre portefeuille' : 'retirés'}.'
                  : 'Le paiement n’a pas abouti. Aucun montant n’a été débité.',
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: succeeded ? 'Continuer' : 'Réessayer',
              onPressed: succeeded
                  ? () => context.pop(true)
                  : () => ref.read(walletOperationProvider(widget.kind).notifier).reset(),
            ),
          ],
        OperationError(:final message) => [
            InfoBanner(icon: Icons.error_outline_rounded, tone: InfoBannerTone.error, title: message),
          ],
        _ => const [Text('Aucun montant n’est débité avant votre validation.', style: AppTextStyles.caption)],
      };
}
