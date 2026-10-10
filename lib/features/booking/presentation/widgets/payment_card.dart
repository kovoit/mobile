import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/booking.dart';
import 'booking_labels.dart';

/// Paiement d'une réservation : moyen choisi, statut, et bouton « Payer » quand l'API l'autorise.
class PaymentCard extends StatelessWidget {
  const PaymentCard({super.key, required this.booking, required this.onPay, this.isPaying = false});

  final Booking booking;

  /// Reçoit le numéro Flooz / Mixx saisi (E.164).
  final ValueChanged<String> onPay;
  final bool isPaying;

  @override
  Widget build(BuildContext context) {
    final payment = booking.payment;
    final pending = payment.status == PaymentStatus.enAttente;
    return KovoitCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(payment.method.icon, color: AppColors.textPrimary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Paiement · ${payment.method.label}', style: AppTextStyles.label),
                    Text(Formatters.fcfa(payment.montant), style: AppTextStyles.caption),
                  ],
                ),
              ),
              StatusChip(label: payment.status.label, tone: payment.status.tone),
            ],
          ),
          if (pending) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    payment.message ?? 'Validez le paiement sur votre téléphone.',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ],
          if (payment.status == PaymentStatus.echoue) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              payment.message ?? 'Le paiement n’a pas abouti. Vous pouvez réessayer.',
              style: AppTextStyles.caption.copyWith(color: AppColors.error),
            ),
          ],
          if (booking.can(BookingAction.payer)) ...[
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: 'Payer ${Formatters.fcfa(payment.montant)} avec ${payment.method.label}',
              icon: Icons.phone_iphone_rounded,
              isLoading: isPaying,
              onPressed: () => _askPhone(context),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _askPhone(BuildContext context) async {
    final phone = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _PhoneSheet(method: booking.payment.method, initialPhone: booking.payment.telephone),
    );
    if (phone != null) onPay(phone);
  }
}

class _PhoneSheet extends StatefulWidget {
  const _PhoneSheet({required this.method, this.initialPhone});

  final PaymentMethod method;
  final String? initialPhone;

  @override
  State<_PhoneSheet> createState() => _PhoneSheetState();
}

class _PhoneSheetState extends State<_PhoneSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _controller = TextEditingController(text: widget.initialPhone?.replaceFirst('+228', '') ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, Validators.normalizeTogoPhone(_controller.text));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        0,
        AppSpacing.screenPadding,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Numéro ${widget.method.label}', style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Une demande de paiement ${widget.method.operator} sera envoyée à ce numéro.',
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: AppSpacing.md),
            KovoitTextField(
              controller: _controller,
              hint: '+228 90 00 00 00',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))],
              validator: Validators.togoPhone,
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(label: 'Envoyer la demande de paiement', onPressed: _confirm),
          ],
        ),
      ),
    );
  }
}
