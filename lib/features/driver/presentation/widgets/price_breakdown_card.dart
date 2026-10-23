import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/price_breakdown.dart';

final NumberFormat _decimal = NumberFormat('#,##0.##', 'fr');
String _fcfaDecimal(double value) => Formatters.fcfa(value.round());

/// Détail du prix calculé par Kovoit : estimation avant publication, ou calcul figé du trajet.
/// [paidSeats] : places réellement payées (trajet publié) pour la participation du conducteur.
class PriceBreakdownCard extends StatelessWidget {
  const PriceBreakdownCard({super.key, required this.pricing, this.paidSeats});

  final PriceBreakdown pricing;
  final int? paidSeats;

  @override
  Widget build(BuildContext context) {
    final p = pricing;
    final taux = _decimal.format(p.tauxCommissionPct);
    return KovoitCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calculate_outlined, color: AppColors.accent),
              const SizedBox(width: AppSpacing.xs),
              const Expanded(child: Text('Prix calculé par Kovoit', style: AppTextStyles.cardTitle)),
              Text(Formatters.fcfa(p.prixPlace), style: AppTextStyles.price),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          const Text('par place · partage des frais du trajet', style: AppTextStyles.caption),
          if (p.estimatedRoute) ...[
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Itinéraire indisponible : distance et durée estimées.',
              style: AppTextStyles.caption,
            ),
          ],
          const Divider(height: AppSpacing.lg),
          _Row(
            '${p.typeVehicule == 'moto' ? 'Moto' : 'Voiture'} · '
                '${Formatters.distanceKm(p.distanceKm)} · ${Formatters.durationMin(p.dureeMin)}',
            '',
          ),
          _Row(
            'Consommation retenue',
            '${_decimal.format(p.consommationL100km)} L/100 km'
                '${p.vehicleConsumption ? '' : ' (référence)'}',
          ),
          _Row(
            'Carburant (${_decimal.format(p.carburantLitres)} L à ${Formatters.fcfa(p.prixCarburantLitre.round())})',
            _fcfaDecimal(p.coutCarburant),
          ),
          if (p.coutTemps > 0) _Row('Temps', _fcfaDecimal(p.coutTemps)),
          if (p.coutEntretien > 0) _Row('Entretien et usure', _fcfaDecimal(p.coutEntretien)),
          _Row('Coût total estimé', _fcfaDecimal(p.coutTotal), strong: true),
          const Divider(height: AppSpacing.lg),
          _Row('Partagé entre vous et ${p.passagersPrevus} passager(s)', ''),
          _Row('Votre participation si complet', _fcfaDecimal(p.partConducteur)),
          _Row('Commission Kovoit ($taux %) par place', '− ${Formatters.fcfa(p.commissionPlace)}'),
          _Row('Vous recevez par place', Formatters.fcfa(p.netConducteurPlace), strong: true),
          _Row(
            'Si les ${p.passagersPrevus} places sont prises',
            '${Formatters.fcfa(p.netConducteur)} reçus',
          ),
          if (paidSeats != null) ...[
            const Divider(height: AppSpacing.lg),
            _Row(
              'Votre participation avec $paidSeats place(s) payée(s)',
              Formatters.fcfa(p.driverShareFor(paidSeats!)),
              strong: true,
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Les places vides ne sont pas compensées. Le prix est figé à la publication : '
            'il ne change pas pour les passagers qui ont réservé.',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.strong = false});

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final style = strong ? AppTextStyles.label : AppTextStyles.body;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: Text(label, style: style)),
          if (value.isNotEmpty) ...[
            const SizedBox(width: AppSpacing.sm),
            Flexible(flex: 2, child: Text(value, style: style, textAlign: TextAlign.end)),
          ],
        ],
      ),
    );
  }
}
