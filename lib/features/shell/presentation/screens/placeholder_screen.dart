import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';

/// Écran temporaire des onglets, remplacé au fil des sprints.
/// [notice] s'affiche au-dessus (ex. carte « accès restreint » tant que le KYC n'est pas validé).
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.sprint,
    this.notice,
  });

  final String title;
  final String subtitle;
  final String sprint;
  final Widget? notice;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const KovoitAppBar(showBack: false),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          ScreenHeader(title: title, subtitle: subtitle),
          const SizedBox(height: AppSpacing.xl),
          if (notice != null) ...[notice!, const SizedBox(height: AppSpacing.md)],
          InfoBanner(
            icon: Icons.construction_rounded,
            tone: InfoBannerTone.accent,
            title: 'Écran en construction',
            subtitle: 'Prévu au sprint $sprint.',
          ),
        ],
      ),
    );
  }
}
