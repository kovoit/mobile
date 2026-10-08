import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Centre de Lomé, position par défaut de la carte.
const LatLng kLomeCenter = LatLng(6.1319, 1.2228);

/// Aperçu de carte OpenStreetMap (écrans « Conducteurs disponibles » et « Suivi du trajet »).
/// Le tracé [route] et les positions viennent de l'API (OSRM côté backend) :
/// aucun calcul d'itinéraire ni de distance dans l'application.
class MapPreview extends StatelessWidget {
  const MapPreview({
    super.key,
    required this.start,
    required this.end,
    this.route = const [],
    this.vehiclePosition,
    this.startLabel,
    this.endLabel,
    this.height = 190,
    this.interactive = false,
    this.tileProvider,
  });

  final LatLng start;
  final LatLng end;
  final List<LatLng> route;
  final LatLng? vehiclePosition;
  final String? startLabel;
  final String? endLabel;
  final double height;
  final bool interactive;

  /// Injectable pour les tests (le cache de tuiles par défaut exige path_provider).
  final TileProvider? tileProvider;

  static const String _tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String _userAgent = 'com.kovoit.kovoit';

  @override
  Widget build(BuildContext context) {
    final points = route.isNotEmpty ? route : [start, end];
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: SizedBox(
        height: height,
        child: ColoredBox(
          color: AppColors.mapPlaceholder,
          child: FlutterMap(
            options: MapOptions(
              initialCameraFit: CameraFit.coordinates(
                coordinates: [start, end, ...route],
                padding: const EdgeInsets.all(36),
              ),
              interactionOptions: InteractionOptions(
                flags: interactive ? InteractiveFlag.all & ~InteractiveFlag.rotate : InteractiveFlag.none,
              ),
            ),
            children: [
              TileLayer(urlTemplate: _tileUrl, userAgentPackageName: _userAgent, tileProvider: tileProvider),
              PolylineLayer(
                polylines: [Polyline(points: points, strokeWidth: 5, color: AppColors.primary)],
              ),
              MarkerLayer(
                markers: [
                  Marker(point: start, width: 18, height: 18, child: const _Dot(color: AppColors.accent)),
                  Marker(point: end, width: 18, height: 18, child: const _Dot(color: AppColors.primary)),
                  if (vehiclePosition != null)
                    Marker(point: vehiclePosition!, width: 34, height: 34, child: const _VehicleMarker()),
                ],
              ),
              if (startLabel != null) _CornerLabel(text: startLabel!, alignment: Alignment.bottomLeft),
              if (endLabel != null) _CornerLabel(text: endLabel!, alignment: Alignment.topRight),
              const RichAttributionWidget(
                showFlutterMapAttribution: false,
                attributions: [TextSourceAttribution('© OpenStreetMap')],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
      ),
    );
  }
}

class _VehicleMarker extends StatelessWidget {
  const _VehicleMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: const Icon(Icons.directions_car_filled_rounded, size: 16, color: Colors.white),
    );
  }
}

class _CornerLabel extends StatelessWidget {
  const _CornerLabel({required this.text, required this.alignment});

  final String text;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.sm),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs + 2, vertical: AppSpacing.xxs + 2),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: AppShadows.card,
        ),
        child: Text(text, style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
