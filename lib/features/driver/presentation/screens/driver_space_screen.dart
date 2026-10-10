import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
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
import '../../../search/presentation/screens/place_picker_screen.dart';
import '../../../trip/domain/entities/geo_place.dart';
import '../../../vehicle/domain/entities/vehicle.dart';
import '../../../vehicle/presentation/providers/vehicle_providers.dart';
import '../../domain/entities/driver_trip.dart';
import '../providers/driver_providers.dart';
import '../widgets/driver_trip_tile.dart';
import '../widgets/savings_card.dart';

/// Maquette « Espace Conducteur » (accueil en mode conducteur) : économies du mois et publication.
/// Le sélecteur Passager / Conducteur de la maquette est retiré : la bascule est dans le Profil.
class DriverSpaceScreen extends ConsumerStatefulWidget {
  const DriverSpaceScreen({super.key});

  @override
  ConsumerState<DriverSpaceScreen> createState() => _DriverSpaceScreenState();
}

class _DriverSpaceScreenState extends ConsumerState<DriverSpaceScreen> {
  bool _publishing = false;

  PublishFormController get _form => ref.read(publishFormProvider.notifier);

  Future<GeoPlace?> _pickPlace(PlaceField field) =>
      context.push<GeoPlace>(Routes.placePicker(field.param));

  Future<void> _pickDate() async {
    final date = await LomePickers.pickDate(
      context,
      now: ref.read(clockProvider)(),
      current: ref.read(publishFormProvider).dateTime,
    );
    if (date != null) _form.setDate(date);
  }

  Future<void> _pickTime() async {
    final time = await LomePickers.pickTime(
      context,
      current: ref.read(publishFormProvider).dateTime,
      helpText: 'Heure de départ',
    );
    if (time != null) _form.setTime(time.hour, time.minute);
  }

  Future<void> _publish(Vehicle vehicle) async {
    final draft = _form.submit(maxPlaces: vehicle.nbPlaces - 1);
    if (draft == null) return;
    setState(() => _publishing = true);
    try {
      final trip = await ref.read(driverRepositoryProvider).publish(draft);
      ref.read(myDriverTripsProvider.notifier).upsert(trip);
      _form.reset();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trajet publié.')));
      await context.push(Routes.driverTrip(trip.id));
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e is BadRequestApiException) _form.applyServerErrors(e.fieldErrors);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionControllerProvider).value;
    final denial = user == null ? null : AccessPolicy.canPublish(user);
    final vehicle = ref.watch(myVehicleProvider).value;

    return Scaffold(
      appBar: const KovoitAppBar(showBack: false),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(driverSavingsProvider);
          await ref.read(myDriverTripsProvider.notifier).refresh();
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            const ScreenHeader(title: 'Espace Conducteur', subtitle: 'Partagez votre route. Allégez vos dépenses.'),
            const SizedBox(height: AppSpacing.lg),
            if (denial != null)
              AccessRequiredCard(denial: denial, suspendedUntil: user?.suspenduJusquAu)
            else ...[
              SavingsCard(savings: ref.watch(driverSavingsProvider).value),
              const SizedBox(height: AppSpacing.lg),
              const _UpcomingTrips(),
              if (vehicle == null)
                const Center(child: CircularProgressIndicator())
              else
                _PublishSection(
                  vehicle: vehicle,
                  publishing: _publishing,
                  onPickDepart: () async {
                    final place = await _pickPlace(PlaceField.depart);
                    if (place != null) _form.setDepart(place);
                  },
                  onPickArrivee: () async {
                    final place = await _pickPlace(PlaceField.arrivee);
                    if (place != null) _form.setArrivee(place);
                  },
                  onAddPickup: () async {
                    final place = await _pickPlace(PlaceField.carrefour);
                    if (place != null) _form.addPickup(place);
                  },
                  onPickDate: _pickDate,
                  onPickTime: _pickTime,
                  onPublish: () => _publish(vehicle),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PublishSection extends ConsumerWidget {
  const _PublishSection({
    required this.vehicle,
    required this.publishing,
    required this.onPickDepart,
    required this.onPickArrivee,
    required this.onAddPickup,
    required this.onPickDate,
    required this.onPickTime,
    required this.onPublish,
  });

  final Vehicle vehicle;
  final bool publishing;
  final VoidCallback onPickDepart;
  final VoidCallback onPickArrivee;
  final VoidCallback onAddPickup;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(publishFormProvider);
    final controller = ref.read(publishFormProvider.notifier);
    final errors = form.errors;
    final maxPlaces = vehicle.nbPlaces - 1;
    final isMoto = vehicle.type == VehicleType.moto;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: Text('Publier un trajet', style: AppTextStyles.title)),
            StatusChip(
              label: isMoto ? 'Moto' : 'Voiture',
              tone: StatusTone.warning,
              icon: isMoto ? Icons.two_wheeler_rounded : Icons.directions_car_filled_outlined,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        KovoitCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PickerField(
                label: 'Point de départ',
                icon: Icons.search_rounded,
                hint: 'Carrefour, quartier, repère…',
                value: form.depart?.fullLabel,
                errorText: errors[PublishField.depart],
                onTap: onPickDepart,
              ),
              const SizedBox(height: AppSpacing.md),
              PickerField(
                label: 'Destination',
                icon: Icons.location_on_outlined,
                iconColor: AppColors.accent,
                hint: 'Où allez-vous ?',
                value: form.arrivee?.fullLabel,
                errorText: errors[PublishField.arrivee],
                onTap: onPickArrivee,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  const Expanded(child: Text('Carrefours de prise en charge', style: AppTextStyles.label)),
                  Text('${form.pickups.length} / ${PublishForm.maxPickups}', style: AppTextStyles.caption),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              for (final pickup in form.pickups) ...[
                _PickupTile(place: pickup, onRemove: () => controller.removePickup(pickup)),
                const SizedBox(height: AppSpacing.xs),
              ],
              if (form.canAddPickup)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: onAddPickup,
                    icon: const Icon(Icons.add_rounded, color: AppColors.textPrimary),
                    label: Text(
                      'Ajouter un carrefour (${PublishForm.maxPickups} maximum)',
                      style: AppTextStyles.label.copyWith(color: AppColors.textPrimary),
                    ),
                  ),
                ),
              if (errors[PublishField.pickups] != null)
                Text(errors[PublishField.pickups]!, style: AppTextStyles.caption.copyWith(color: AppColors.error)),
              const Text(
                'Les passagers pourront vous rejoindre à ces points, dans l’ordre du trajet.',
                style: AppTextStyles.caption,
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: AppSpacing.md), child: Divider()),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: PickerField(
                      label: 'Date',
                      icon: Icons.calendar_today_outlined,
                      hint: 'Date',
                      value: Formatters.date(form.dateTime),
                      onTap: onPickDate,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: PickerField(
                      label: 'Heure',
                      icon: Icons.schedule_rounded,
                      hint: 'Heure',
                      value: Formatters.time(form.dateTime),
                      onTap: onPickTime,
                    ),
                  ),
                ],
              ),
              if (errors[PublishField.dateTime] != null) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(errors[PublishField.dateTime]!, style: AppTextStyles.caption.copyWith(color: AppColors.error)),
              ],
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  const Icon(Icons.people_outline_rounded, color: AppColors.textPrimary),
                  const SizedBox(width: AppSpacing.sm),
                  const Expanded(child: Text('Places disponibles', style: AppTextStyles.label)),
                  PlaceStepper(
                    value: form.places.clamp(1, maxPlaces),
                    max: maxPlaces,
                    onChanged: (v) => controller.setPlaces(v, max: maxPlaces),
                  ),
                ],
              ),
              if (errors[PublishField.places] != null)
                Text(errors[PublishField.places]!, style: AppTextStyles.caption.copyWith(color: AppColors.error)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (form.depart != null && form.arrivee != null && form.depart != form.arrivee) ...[
          _PriceBanner(depart: form.depart!, arrivee: form.arrivee!, vehicleType: vehicle.type),
          const SizedBox(height: AppSpacing.md),
        ],
        PrimaryButton(
          label: 'Publier mon trajet',
          icon: Icons.arrow_forward_rounded,
          isLoading: publishing,
          onPressed: onPublish,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${vehicle.label} · ${vehicle.immatriculation} · profil vérifié',
          textAlign: TextAlign.center,
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
}

class _PickupTile extends StatelessWidget {
  const _PickupTile({required this.place, required this.onRemove});

  final GeoPlace place;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: BorderRadius.circular(AppRadius.field),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, size: 20, color: AppColors.accent),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: Text(place.libelle, style: AppTextStyles.body, overflow: TextOverflow.ellipsis)),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded, size: 20),
            tooltip: 'Retirer ${place.libelle}',
          ),
        ],
      ),
    );
  }
}

/// « Prix recommandé : 300 FCFA » : calculé par le backend, jamais saisi par le conducteur.
class _PriceBanner extends ConsumerWidget {
  const _PriceBanner({required this.depart, required this.arrivee, required this.vehicleType});

  final GeoPlace depart;
  final GeoPlace arrivee;
  final VehicleType vehicleType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estimate = ref.watch(priceEstimateProvider((depart, arrivee, vehicleType)));
    return switch (estimate) {
      AsyncValue(:final value?) => InfoBanner(
          icon: Icons.calculate_outlined,
          tone: InfoBannerTone.accent,
          title: 'Prix recommandé : ${Formatters.fcfa(value.prixPlace)}',
          subtitle: 'Calculé automatiquement · par place, pour ce trajet '
              '(${Formatters.distanceKm(value.distanceKm)}).',
        ),
      AsyncValue(:final error?) => InfoBanner(
          icon: Icons.calculate_outlined,
          tone: InfoBannerTone.error,
          title: 'Prix indisponible pour le moment',
          subtitle: error is ApiException ? error.message : null,
        ),
      _ => const InfoBanner(icon: Icons.calculate_outlined, tone: InfoBannerTone.accent, title: 'Calcul du prix…'),
    };
  }
}

/// Prochains trajets publiés (raccourci vers leur gestion), avec le nombre de demandes en attente.
class _UpcomingTrips extends ConsumerWidget {
  const _UpcomingTrips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trips = (ref.watch(myDriverTripsProvider).value ?? const <DriverTrip>[])
        .where((t) => t.status.isUpcoming)
        .take(3)
        .toList();
    if (trips.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Mes prochains trajets', style: AppTextStyles.title),
        const SizedBox(height: AppSpacing.xs),
        for (final trip in trips) ...[
          DriverTripTile(trip: trip, onTap: () => context.push(Routes.driverTrip(trip.id))),
          const SizedBox(height: AppSpacing.xs),
        ],
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}
