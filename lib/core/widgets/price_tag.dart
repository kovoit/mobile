import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';
import '../utils/formatters.dart';

/// Montant mis en avant (« 300 FCFA » + « par place → »).
/// [amount] est la valeur renvoyée par l'API : aucun calcul ici.
class PriceTag extends StatelessWidget {
  const PriceTag({super.key, required this.amount, this.caption, this.alignEnd = true});

  final int amount;
  final String? caption;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(Formatters.fcfa(amount), style: AppTextStyles.price),
        if (caption != null) Text(caption!, style: AppTextStyles.caption),
      ],
    );
  }
}
