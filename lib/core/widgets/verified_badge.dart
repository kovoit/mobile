import 'package:flutter/material.dart';

import 'status_chip.dart';

/// Badge vert « Identité vérifiée » (KYC `verifie` renvoyé par l'API).
class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key, this.label = 'Identité vérifiée'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return StatusChip(label: label, tone: StatusTone.success, icon: Icons.verified_outlined);
  }
}
