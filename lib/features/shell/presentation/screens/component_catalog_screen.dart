import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';

enum _VehicleType { moto, voiture }

enum _Mode { passager, conducteur }

/// Catalogue des composants partagés (dev uniquement) pour vérifier le rendu face aux maquettes.
/// Les valeurs affichées sont des exemples fictifs, pas des règles métier.
class ComponentCatalogScreen extends StatefulWidget {
  const ComponentCatalogScreen({super.key});

  @override
  State<ComponentCatalogScreen> createState() => _ComponentCatalogScreenState();
}

class _ComponentCatalogScreenState extends State<ComponentCatalogScreen> {
  _VehicleType _vehicle = _VehicleType.voiture;
  _Mode _mode = _Mode.conducteur;
  int _places = 1;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const KovoitAppBar(),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          const ScreenHeader(title: 'Composants', subtitle: 'Design system Kovoit (maquettes Figma).'),
          _section('Logo'),
          const Row(children: [KovoitLogo(size: 56, framed: true), SizedBox(width: AppSpacing.md), KovoitLogo(size: 40)]),
          _section('Bascules'),
          SegmentedToggle<_VehicleType>(
            selected: _vehicle,
            onChanged: (v) => setState(() => _vehicle = v),
            options: const [
              SegmentedOption(value: _VehicleType.moto, label: 'Moto', icon: Icons.two_wheeler_rounded),
              SegmentedOption(value: _VehicleType.voiture, label: 'Voiture', icon: Icons.directions_car_filled_outlined),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SegmentedToggle<_Mode>(
            selected: _mode,
            onChanged: (v) => setState(() => _mode = v),
            options: const [
              SegmentedOption(value: _Mode.passager, label: 'Passager', icon: Icons.person_outline_rounded),
              SegmentedOption(value: _Mode.conducteur, label: 'Conducteur', icon: Icons.directions_car_outlined),
            ],
          ),
          _section('Champs'),
          const KovoitTextField(label: 'Point de départ', hint: 'Carrefour Franciscain, Adidogomé', prefixIcon: Icons.search_rounded),
          const SizedBox(height: AppSpacing.md),
          const KovoitTextField(
            label: 'Destination',
            hint: 'Université de Lomé · Entrée sud',
            prefixIcon: Icons.location_on_outlined,
            prefixIconColor: AppColors.accent,
          ),
          const SizedBox(height: AppSpacing.md),
          const KovoitTextField(label: 'Mot de passe', hint: '••••••••', prefixIcon: Icons.lock_outline_rounded, isPassword: true),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Expanded(child: Text('Nombre de places', style: AppTextStyles.label)),
              PlaceStepper(value: _places, max: 3, onChanged: (v) => setState(() => _places = v)),
            ],
          ),
          _section('Code OTP SMS (6) et code de départ (4)'),
          const OtpCodeInput(),
          const SizedBox(height: AppSpacing.sm),
          const OtpCodeInput(length: 4),
          _section('Boutons'),
          PrimaryButton(
            label: 'Rechercher un trajet',
            icon: Icons.search_rounded,
            isLoading: _loading,
            onPressed: () async {
              setState(() => _loading = true);
              await Future<void>.delayed(const Duration(seconds: 1));
              if (mounted) setState(() => _loading = false);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          PrimaryButton.outlined(label: 'Annuler', onPressed: () {}),
          const SizedBox(height: AppSpacing.sm),
          const PrimaryButton(label: 'Désactivé', onPressed: null),
          _section('Statuts'),
          const Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              VerifiedBadge(),
              StatusChip(label: 'Terminé', tone: StatusTone.success, icon: Icons.check_rounded),
              StatusChip(label: 'À capturer', tone: StatusTone.warning, icon: Icons.photo_camera_outlined),
              StatusChip(label: 'Refusée', tone: StatusTone.error),
              StatusChip(label: 'En attente', tone: StatusTone.neutral),
              RatingLabel(rating: 4.9),
            ],
          ),
          _section('Bandeaux'),
          const InfoBanner(icon: Icons.eco_outlined, title: 'Moins de véhicules. Plus de bonnes rencontres.'),
          const SizedBox(height: AppSpacing.sm),
          const InfoBanner(
            icon: Icons.calculate_outlined,
            tone: InfoBannerTone.accent,
            title: 'Prix recommandé : 300 FCFA',
            subtitle: 'Calculé automatiquement · par place, pour ce trajet.',
          ),
          const SizedBox(height: AppSpacing.sm),
          const InfoBanner(
            icon: Icons.eco_outlined,
            tone: InfoBannerTone.primary,
            title: 'Mes économies ce mois : 18 500 FCFA',
            subtitle: 'Octobre · 24 places partagées',
          ),
          _section('Progression KYC'),
          const StepProgress(
            completed: 3,
            total: 4,
            stepLabels: ['Photo de profil', "Pièce d'identité", 'Selfie'],
          ),
          _section('Carte conducteur'),
          DriverCard(
            driverName: 'Kodjo Mensah',
            rating: 4.9,
            isVerified: true,
            vehicleLabel: 'Toyota Yaris',
            placesLabel: '2 places restantes',
            departureLabel: 'Départ 07:30 · 1.2 km de vous',
            routeLabel: 'Adidogomé → Université de Lomé',
            price: 300,
            onTap: () {},
          ),
          _section('Carte OpenStreetMap'),
          const MapPreview(
            start: LatLng(6.1530, 1.1660),
            end: LatLng(6.1740, 1.2130),
            startLabel: 'Carrefour Franciscain',
            endLabel: 'Université de Lomé',
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.sm),
        child: Text(title, style: AppTextStyles.title),
      );
}
