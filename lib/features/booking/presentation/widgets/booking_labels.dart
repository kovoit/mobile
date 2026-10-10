import 'package:flutter/material.dart';

import '../../../../core/widgets/status_chip.dart';
import '../../domain/entities/booking.dart';

extension BookingStatusLabels on BookingStatus {
  String get label => switch (this) {
        BookingStatus.demandee => 'En attente',
        BookingStatus.acceptee => 'Acceptée',
        BookingStatus.refusee => 'Refusée',
        BookingStatus.annulee => 'Annulée',
        BookingStatus.absent => 'Absent',
        BookingStatus.enCours => 'En cours',
        BookingStatus.terminee => 'Terminée',
        BookingStatus.litige => 'Litige',
        BookingStatus.cloturee => 'Clôturée',
      };

  StatusChip get chip => switch (this) {
        BookingStatus.demandee => StatusChip(label: label, tone: StatusTone.warning, icon: Icons.hourglass_top_rounded),
        BookingStatus.acceptee => StatusChip(label: label, tone: StatusTone.success, icon: Icons.check_rounded),
        BookingStatus.enCours => StatusChip(label: label, tone: StatusTone.info, icon: Icons.directions_car_rounded),
        BookingStatus.terminee => StatusChip(label: label, tone: StatusTone.success),
        BookingStatus.refusee || BookingStatus.absent || BookingStatus.litige =>
          StatusChip(label: label, tone: StatusTone.error),
        BookingStatus.annulee || BookingStatus.cloturee => StatusChip(label: label),
      };
}

extension PaymentMethodLabels on PaymentMethod {
  /// « Flooz » / « Mixx » / « Espèces » (jamais « T-Money », retour UX du 08/10).
  String get label => switch (this) {
        PaymentMethod.especes => 'Espèces',
        PaymentMethod.flooz => 'Flooz',
        PaymentMethod.mixx => 'Mixx',
      };

  String get operator => switch (this) {
        PaymentMethod.especes => 'Au conducteur',
        PaymentMethod.flooz => 'Moov Africa',
        PaymentMethod.mixx => 'Togocom',
      };

  IconData get icon => isMobileMoney ? Icons.phone_iphone_rounded : Icons.payments_outlined;
}

extension PaymentStatusLabels on PaymentStatus {
  String get label => switch (this) {
        PaymentStatus.nonRequis => 'À régler au conducteur',
        PaymentStatus.aPayer => 'À payer',
        PaymentStatus.enAttente => 'Paiement en cours',
        PaymentStatus.reussi => 'Payé',
        PaymentStatus.echoue => 'Paiement échoué',
        PaymentStatus.rembourse => 'Remboursé',
      };

  StatusTone get tone => switch (this) {
        PaymentStatus.reussi || PaymentStatus.rembourse => StatusTone.success,
        PaymentStatus.echoue => StatusTone.error,
        PaymentStatus.aPayer || PaymentStatus.enAttente => StatusTone.warning,
        PaymentStatus.nonRequis => StatusTone.neutral,
      };
}
