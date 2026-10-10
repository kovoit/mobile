import 'package:flutter/material.dart';

import '../../../../core/widgets/status_chip.dart';
import '../../domain/entities/driver_trip.dart';

extension TripStatusLabels on TripStatus {
  String get label => switch (this) {
        TripStatus.publie => 'Publié',
        TripStatus.complet => 'Complet',
        TripStatus.enCours => 'En cours',
        TripStatus.termine => 'Terminé',
        TripStatus.annule => 'Annulé',
      };

  StatusChip get chip => switch (this) {
        TripStatus.publie => StatusChip(label: label, tone: StatusTone.info, icon: Icons.campaign_outlined),
        TripStatus.complet => StatusChip(label: label, tone: StatusTone.success, icon: Icons.event_seat_outlined),
        TripStatus.enCours => StatusChip(label: label, tone: StatusTone.info, icon: Icons.directions_car_rounded),
        TripStatus.termine => StatusChip(label: label, tone: StatusTone.success, icon: Icons.flag_outlined),
        TripStatus.annule => StatusChip(label: label),
      };
}
