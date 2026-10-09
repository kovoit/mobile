import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../trip/domain/entities/geo_place.dart';
import '../providers/search_providers.dart';

/// Choix d'un lieu : lieux connus de Lomé (carrefours, quartiers, repères) ou point sur la carte.
/// Renvoie le [GeoPlace] choisi via `context.pop`.
class PlacePickerScreen extends ConsumerStatefulWidget {
  const PlacePickerScreen({super.key, required this.isDepart});

  final bool isDepart;

  @override
  ConsumerState<PlacePickerScreen> createState() => _PlacePickerScreenState();
}

class _PlacePickerScreenState extends ConsumerState<PlacePickerScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  Future<void> _pickOnMap() async {
    final place = await context.push<GeoPlace>(Routes.mapPicker);
    if (place != null && mounted) context.pop(place);
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = ref.watch(placeSuggestionsProvider(_query));

    return Scaffold(
      appBar: const KovoitAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, 0, AppSpacing.screenPadding, AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ScreenHeader(
                  title: widget.isDepart ? 'Point de départ' : 'Destination',
                  subtitle: 'Un carrefour, un quartier ou un repère connu.',
                ),
                const SizedBox(height: AppSpacing.md),
                KovoitTextField(
                  controller: _controller,
                  hint: 'Ex. Carrefour Franciscain',
                  prefixIcon: widget.isDepart ? Icons.search_rounded : Icons.location_on_outlined,
                  prefixIconColor: widget.isDepart ? null : AppColors.accent,
                  textInputAction: TextInputAction.search,
                  onChanged: _onChanged,
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: _pickOnMap,
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Choisir sur la carte'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                ),
              ],
            ),
          ),
          Expanded(
            child: switch (suggestions) {
              AsyncValue(:final value?) when value.isEmpty => const _Empty(),
              AsyncValue(:final value?) => ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                  itemCount: value.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, index) => _PlaceTile(place: value[index], onTap: () => context.pop(value[index])),
                ),
              AsyncValue(:final error?) => Center(
                  child: Text(
                    error is ApiException ? error.message : 'Impossible de charger les lieux.',
                    style: AppTextStyles.subtitle,
                  ),
                ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }
}

class _PlaceTile extends StatelessWidget {
  const _PlaceTile({required this.place, required this.onTap});

  final GeoPlace place;
  final VoidCallback onTap;

  IconData get _icon => switch (place.type) {
        GeoPlaceType.carrefour => Icons.alt_route_rounded,
        GeoPlaceType.quartier => Icons.location_city_rounded,
        GeoPlaceType.repere => Icons.place_outlined,
        GeoPlaceType.pointCarte => Icons.my_location_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: AppColors.fieldFill,
        child: Icon(_icon, color: AppColors.textPrimary, size: 20),
      ),
      title: Text(place.libelle, style: AppTextStyles.label),
      subtitle: place.quartier == null ? null : Text(place.quartier!, style: AppTextStyles.caption),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.xl),
      child: Text(
        'Aucun lieu connu ne correspond. Essayez un carrefour proche, ou choisissez le point sur la carte.',
        textAlign: TextAlign.center,
        style: AppTextStyles.subtitle,
      ),
    );
  }
}
