import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/clock.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/domain/access_policy.dart';
import '../../../auth/presentation/providers/session_controller.dart';
import '../../../kyc/presentation/widgets/access_required_card.dart';
import '../../../trip/domain/entities/geo_place.dart';
import '../../../vehicle/domain/entities/vehicle.dart';
import '../../domain/repositories/search_repository.dart';
import '../providers/search_providers.dart';

/// Maquette « Rechercher un trajet » (accueil en mode passager).
/// La recherche est ouverte dès le téléphone vérifié ; seule la réservation exige le KYC.
class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  Future<void> _pickPlace(BuildContext context, WidgetRef ref, {required bool isDepart}) async {
    final place = await context.push<GeoPlace>(Routes.placePicker(isDepart ? 'depart' : 'arrivee'));
    if (place == null) return;
    final form = ref.read(searchFormProvider.notifier);
    isDepart ? form.setDepart(place) : form.setArrivee(place);
  }

  Future<void> _pickDate(BuildContext context, WidgetRef ref) async {
    // Dates en heure de Lomé (UTC) : on passe au sélecteur des dates « murales » sans fuseau.
    final now = ref.read(clockProvider)().toUtc();
    final today = DateTime(now.year, now.month, now.day);
    final current = ref.read(searchFormProvider).dateTime;
    final currentDay = DateTime(current.year, current.month, current.day);
    final date = await showDatePicker(
      context: context,
      initialDate: currentDay.isBefore(today) ? today : currentDay,
      firstDate: today,
      lastDate: today.add(const Duration(days: 30)),
      helpText: 'Date du trajet',
    );
    if (date != null) ref.read(searchFormProvider.notifier).setDate(date);
  }

  Future<void> _pickTime(BuildContext context, WidgetRef ref) async {
    final current = ref.read(searchFormProvider).dateTime;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
      helpText: 'Heure de départ souhaitée',
      builder: (context, child) =>
          MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: child!),
    );
    if (time != null) ref.read(searchFormProvider.notifier).setTime(time.hour, time.minute);
  }

  void _search(BuildContext context, WidgetRef ref) {
    final query = ref.read(searchFormProvider.notifier).submit();
    if (query == null) return;
    ref.read(recentSearchesProvider.notifier).remember(query);
    context.push(Uri(path: Routes.searchResults, queryParameters: query.toQueryParameters()).toString());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(searchFormProvider);
    final user = ref.watch(sessionControllerProvider).value;
    final bookingDenial = user == null ? null : AccessPolicy.canBook(user);
    final recents = ref.watch(recentSearchesProvider).value ?? const <RecentSearch>[];
    final errors = form.errors;

    return Scaffold(
      appBar: const KovoitAppBar(showBack: false),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          const ScreenHeader(title: 'Rechercher un trajet', subtitle: 'Le même chemin, à plusieurs. Et moins cher.'),
          const SizedBox(height: AppSpacing.lg),
          if (bookingDenial != null) ...[
            AccessRequiredCard(denial: bookingDenial, suspendedUntil: user?.suspenduJusquAu),
            const SizedBox(height: AppSpacing.md),
          ],
          SegmentedToggle<VehicleType>(
            selected: form.vehicleType,
            onChanged: ref.read(searchFormProvider.notifier).setVehicleType,
            options: const [
              SegmentedOption(value: VehicleType.moto, label: 'Moto', icon: Icons.two_wheeler_rounded),
              SegmentedOption(value: VehicleType.voiture, label: 'Voiture', icon: Icons.directions_car_filled_outlined),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          KovoitCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PickerField(
                  label: 'Point de départ',
                  icon: Icons.search_rounded,
                  hint: 'Carrefour, quartier, repère…',
                  value: form.depart?.fullLabel,
                  errorText: errors[SearchFormField.depart],
                  onTap: () => _pickPlace(context, ref, isDepart: true),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: form.depart == null && form.arrivee == null
                        ? null
                        : ref.read(searchFormProvider.notifier).swapPlaces,
                    icon: const Icon(Icons.swap_vert_rounded),
                    tooltip: 'Inverser départ et destination',
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                PickerField(
                  label: 'Destination',
                  icon: Icons.location_on_outlined,
                  iconColor: AppColors.accent,
                  hint: 'Où allez-vous ?',
                  value: form.arrivee?.fullLabel,
                  errorText: errors[SearchFormField.arrivee],
                  onTap: () => _pickPlace(context, ref, isDepart: false),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: PickerField(
                        label: 'Date',
                        icon: Icons.calendar_today_outlined,
                        hint: 'Date',
                        value: Formatters.date(form.dateTime),
                        onTap: () => _pickDate(context, ref),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: PickerField(
                        label: 'Heure',
                        icon: Icons.schedule_rounded,
                        hint: 'Heure',
                        value: Formatters.time(form.dateTime),
                        onTap: () => _pickTime(context, ref),
                      ),
                    ),
                  ],
                ),
                if (errors[SearchFormField.dateTime] != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    errors[SearchFormField.dateTime]!,
                    style: AppTextStyles.caption.copyWith(color: AppColors.error),
                  ),
                ],
                const Padding(padding: EdgeInsets.symmetric(vertical: AppSpacing.md), child: Divider()),
                Row(
                  children: [
                    const Expanded(child: Text('Nombre de places', style: AppTextStyles.label)),
                    PlaceStepper(
                      value: form.places,
                      max: form.maxPlaces,
                      onChanged: ref.read(searchFormProvider.notifier).setPlaces,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: 'Rechercher un trajet',
            icon: Icons.search_rounded,
            onPressed: () => _search(context, ref),
          ),
          if (recents.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            const Text('Vos trajets récents', style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.xs),
            for (final recent in recents) ...[
              _RecentSearchTile(
                recent: recent,
                onTap: () => ref.read(searchFormProvider.notifier).applyRecent(recent),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
          ],
          const SizedBox(height: AppSpacing.md),
          const InfoBanner(icon: Icons.eco_outlined, title: 'Moins de véhicules. Plus de bonnes rencontres.'),
        ],
      ),
    );
  }
}

class _RecentSearchTile extends StatelessWidget {
  const _RecentSearchTile({required this.recent, required this.onTap});

  final RecentSearch recent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isMoto = VehicleType.fromApi(recent.vehicleTypeApi) == VehicleType.moto;
    return KovoitCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          const Icon(Icons.history_rounded, color: AppColors.textPrimary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${recent.depart.displayName} → ${recent.arrivee.displayName}',
                  style: AppTextStyles.label,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(isMoto ? 'En moto' : 'En voiture', style: AppTextStyles.caption),
              ],
            ),
          ),
          const Icon(Icons.north_west_rounded, size: 20, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
