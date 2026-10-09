import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../trip/domain/entities/geo_place.dart';

/// Choix d'un point sur la carte OpenStreetMap : l'utilisateur déplace la carte sous un repère fixe.
/// Pas de géocodage inverse dans le MVP : le point est nommé « Point choisi sur la carte ».
class MapPickerScreen extends ConsumerStatefulWidget {
  const MapPickerScreen({super.key});

  @override
  ConsumerState<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends ConsumerState<MapPickerScreen> {
  final _mapController = MapController();
  LatLng _center = kLomeCenter;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _confirm() => context.pop(
        GeoPlace(
          libelle: 'Point choisi sur la carte',
          type: GeoPlaceType.pointCarte,
          lat: double.parse(_center.latitude.toStringAsFixed(5)),
          lng: double.parse(_center.longitude.toStringAsFixed(5)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const KovoitAppBar(),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: kLomeCenter,
              initialZoom: 14,
              minZoom: 11,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
              onPositionChanged: (camera, _) => _center = camera.center,
            ),
            children: [
              TileLayer(
                urlTemplate: kOsmTileUrl,
                userAgentPackageName: kOsmUserAgent,
                tileProvider: ref.watch(mapTileProviderProvider),
              ),
              const RichAttributionWidget(
                showFlutterMapAttribution: false,
                attributions: [TextSourceAttribution('© OpenStreetMap')],
              ),
            ],
          ),
          // Repère fixe au centre : sa pointe désigne le point choisi.
          const IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 40),
                child: Icon(Icons.location_on_rounded, size: 44, color: AppColors.accent),
              ),
            ),
          ),
          const Positioned(
            top: AppSpacing.md,
            left: AppSpacing.screenPadding,
            right: AppSpacing.screenPadding,
            child: InfoBanner(
              icon: Icons.pan_tool_alt_outlined,
              tone: InfoBannerTone.accent,
              title: 'Déplacez la carte pour placer le repère.',
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: PrimaryButton(label: 'Valider ce point', icon: Icons.check_rounded, onPressed: _confirm),
        ),
      ),
    );
  }
}
