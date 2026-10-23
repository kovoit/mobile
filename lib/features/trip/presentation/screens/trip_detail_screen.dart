import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/domain/access_policy.dart';
import '../../../auth/presentation/providers/session_controller.dart';
import '../../../booking/presentation/providers/booking_providers.dart';
import '../../../kyc/presentation/widgets/access_required_card.dart';
import '../../../vehicle/domain/entities/vehicle.dart';
import '../../domain/entities/trip.dart';
import '../providers/trip_providers.dart';

/// Maquette « Détails & Réservation » : prise en charge, conducteur (note, fiabilité), véhicule
/// (photo + immatriculation), prix et paiement par le portefeuille renvoyés par l'API, demande
/// d'une place. S'il manque de l'argent, le passager recharge le complément (Flooz / Mixx) d'abord.
class TripDetailScreen extends ConsumerStatefulWidget {
  const TripDetailScreen({super.key, required this.tripId, this.pickupId, this.arrivee});

  final String tripId;

  /// Point de prise en charge proposé par la recherche (sinon : le premier du trajet).
  final String? pickupId;

  /// Destination du passager (sinon : l'arrivée du conducteur).
  final ({String libelle, double lat, double lng})? arrivee;

  @override
  ConsumerState<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends ConsumerState<TripDetailScreen> {
  bool _submitting = false;

  String get tripId => widget.tripId;

  Trip _withPickup(Trip trip) => widget.pickupId == null ? trip : trip.withMatch(pickupId: widget.pickupId!);

  Future<void> _book(Trip trip) async {
    final pickup = trip.matchedPickup;
    if (pickup == null) return;
    final destination = widget.arrivee ?? (libelle: trip.arrivee.libelle, lat: trip.arrivee.lat, lng: trip.arrivee.lng);
    setState(() => _submitting = true);
    try {
      final booking = await ref.read(bookingRequesterProvider).request(
            tripId: trip.id,
            pickupPointId: pickup.id,
            arrivee: destination,
          );
      if (mounted) context.pushReplacement(Routes.booking(booking.id));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      // Places, disponibilité ou solde changés : on relit le trajet et l'aperçu du paiement.
      if (e is ConflictApiException || e is NotFoundApiException) ref.invalidate(tripDetailProvider(tripId));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _recharge(int complement) async {
    await context.push<bool>(Routes.walletRecharge(montant: complement));
    if (mounted) ref.invalidate(tripDetailProvider(tripId));
  }

  @override
  Widget build(BuildContext context) {
    final trip = ref.watch(tripDetailProvider(tripId)).whenData(_withPickup);
    final user = ref.watch(sessionControllerProvider).value;
    final denial = user == null ? null : AccessPolicy.canBook(user);
    // Demande déjà en cours sur ce trajet : on renvoie vers son suivi plutôt que d'en créer une autre.
    final existing = ref
        .watch(myBookingsProvider)
        .value
        ?.where((b) => b.trip.id == tripId && b.status.isUpcoming)
        .firstOrNull;

    return Scaffold(
      appBar: const KovoitAppBar(),
      body: switch (trip) {
        AsyncValue(:final value?) => _content(value, denial, user?.suspenduJusquAu, hasExisting: existing != null),
        AsyncValue(:final error?) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    error is ApiException ? error.message : 'Impossible de charger ce trajet.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PrimaryButton.outlined(
                    label: 'Réessayer',
                    onPressed: () => ref.invalidate(tripDetailProvider(tripId)),
                  ),
                ],
              ),
            ),
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
      bottomNavigationBar: switch (trip.value) {
        Trip() when existing != null => _BookingBar(
            label: 'Voir ma réservation',
            onPressed: () => context.pushReplacement(Routes.booking(existing.id)),
          ),
        final value? when denial == null => _BookingBar(
            label: 'Réserver ma place',
            isLoading: _submitting,
            onPressed: value.placesRestantes >= 1 && (value.payment?.complementAPayer ?? 0) == 0
                ? () => _book(value)
                : null,
          ),
        _ => null,
      },
    );
  }

  Widget _content(Trip trip, AccessDenial? denial, DateTime? suspendedUntil, {required bool hasExisting}) {
    final isMoto = trip.vehicle.type == VehicleType.moto;
    final pickup = trip.matchedPickup;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        ScreenHeader(
          title: 'Détails & Réservation',
          subtitle: '${Formatters.longDate(trip.departureAt)} · 1 place en ${isMoto ? 'moto' : 'voiture'}',
        ),
        const SizedBox(height: AppSpacing.lg),
        _ItineraryCard(trip: trip, pickup: pickup),
        const SizedBox(height: AppSpacing.md),
        _DriverCard(trip: trip),
        const SizedBox(height: AppSpacing.md),
        _PriceCard(trip: trip),
        const SizedBox(height: AppSpacing.md),
        if (denial != null)
          AccessRequiredCard(denial: denial, suspendedUntil: suspendedUntil)
        else if (hasExisting)
          const InfoBanner(
            icon: Icons.event_available_rounded,
            title: 'Vous avez déjà une demande sur ce trajet.',
          )
        else ...[
          if (trip.payment != null) _WalletPaymentCard(payment: trip.payment!, onRecharge: _recharge),
          if (trip.placesRestantes < 1) ...[
            const SizedBox(height: AppSpacing.sm),
            const InfoBanner(
              icon: Icons.event_busy_rounded,
              tone: InfoBannerTone.error,
              title: 'Plus assez de places sur ce trajet.',
            ),
          ],
        ],
        const SizedBox(height: AppSpacing.md),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_outlined, size: 18, color: AppColors.textPrimary),
            SizedBox(width: AppSpacing.xs),
            Flexible(child: Text('Code de départ requis à la prise en charge', style: AppTextStyles.caption)),
          ],
        ),
      ],
    );
  }
}

class _ItineraryCard extends StatelessWidget {
  const _ItineraryCard({required this.trip, required this.pickup});

  final Trip trip;
  final PickupPoint? pickup;

  @override
  Widget build(BuildContext context) {
    final pickupPlace = pickup?.place ?? trip.depart;
    final others = trip.pickupPoints.where((p) => p.id != pickup?.id).toList();
    return KovoitCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Stop(
            dotColor: AppColors.accent,
            caption: 'PRISE EN CHARGE · ${Formatters.time(trip.departureAt)}',
            title: pickupPlace.quartier == null ? pickupPlace.libelle : '${pickupPlace.quartier} · ${pickupPlace.libelle}',
            subtitle: trip.walkingDistanceKm == null ? null : 'À ${Formatters.distanceKm(trip.walkingDistanceKm!)} de votre départ',
            showLine: true,
          ),
          _Stop(
            dotColor: AppColors.accent,
            icon: Icons.location_on_outlined,
            caption: 'ARRIVÉE',
            title: trip.arrivee.libelle,
          ),
          if (others.isNotEmpty) ...[
            const Divider(height: AppSpacing.lg),
            Text(
              'Autres points de prise en charge : ${others.map((p) => p.place.libelle).join(', ')}',
              style: AppTextStyles.caption,
            ),
          ],
        ],
      ),
    );
  }
}

class _Stop extends StatelessWidget {
  const _Stop({
    required this.dotColor,
    required this.caption,
    required this.title,
    this.subtitle,
    this.icon,
    this.showLine = false,
  });

  final Color dotColor;
  final IconData? icon;
  final String caption;
  final String title;
  final String? subtitle;
  final bool showLine;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                const SizedBox(height: 2),
                icon == null
                    ? Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: dotColor, width: 3),
                        ),
                      )
                    : Icon(icon, size: 18, color: dotColor),
                if (showLine) Expanded(child: Container(width: 1.5, color: AppColors.border)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: showLine ? AppSpacing.md : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(caption, style: AppTextStyles.caption.copyWith(letterSpacing: 0.3)),
                  const SizedBox(height: 2),
                  Text(title, style: AppTextStyles.cardTitle),
                  if (subtitle != null) Text(subtitle!, style: AppTextStyles.caption),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final driver = trip.driver;
    final vehicle = trip.vehicle;
    return KovoitCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UserAvatar(name: driver.nomComplet, photoUrl: driver.photoUrl, size: 52),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(driver.nomComplet, style: AppTextStyles.cardTitle),
                    const SizedBox(height: AppSpacing.xxs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xxs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (driver.verifie) const VerifiedBadge(),
                        Text(Formatters.ratingsCount(driver.nombreNotes), style: AppTextStyles.caption),
                      ],
                    ),
                  ],
                ),
              ),
              if (driver.note != null) RatingLabel(rating: driver.note!),
            ],
          ),
          if (driver.fiabilite != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(Icons.verified_user_outlined, size: 18, color: AppColors.success),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Fiabilité ${driver.fiabilite} %',
                    style: AppTextStyles.caption.copyWith(color: AppColors.success, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          _VehiclePhoto(vehicle: vehicle),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                vehicle.type == VehicleType.moto ? Icons.two_wheeler_rounded : Icons.directions_car_filled_outlined,
                size: 18,
                color: AppColors.accent,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(child: Text('${vehicle.label} · ${vehicle.couleur}', style: AppTextStyles.label)),
              StatusChip(label: vehicle.immatriculation, tone: StatusTone.info),
            ],
          ),
        ],
      ),
    );
  }
}

class _VehiclePhoto extends StatelessWidget {
  const _VehiclePhoto({required this.vehicle});

  final TripVehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: AppColors.fieldFill,
      alignment: Alignment.center,
      child: Icon(
        vehicle.type == VehicleType.moto ? Icons.two_wheeler_rounded : Icons.directions_car_filled_rounded,
        size: 56,
        color: AppColors.textDisabled,
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.field),
      child: AspectRatio(
        aspectRatio: 16 / 7,
        child: vehicle.photoUrl == null
            ? placeholder
            : Image.network(
                vehicle.photoUrl!,
                fit: BoxFit.cover,
                semanticLabel: 'Photo du véhicule ${vehicle.label}',
                errorBuilder: (_, _, _) => placeholder,
              ),
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final total = trip.payment?.montantTotal;
    return KovoitCard(
      child: Column(
        children: [
          _PriceRow(label: '1 place', value: Formatters.fcfa(trip.prixPlace)),
          if (trip.fraisService > 0) ...[
            const SizedBox(height: AppSpacing.xs),
            _PriceRow(label: 'Frais de réservation', value: Formatters.fcfa(trip.fraisService), muted: true),
          ],
          const SizedBox(height: AppSpacing.xs),
          _PriceRow(label: 'Places restantes', value: '${trip.placesRestantes}', muted: true),
          if (total != null) ...[
            const Divider(height: AppSpacing.lg),
            Row(
              children: [
                const Expanded(child: Text('Total à payer', style: AppTextStyles.cardTitle)),
                Text(Formatters.fcfa(total), style: AppTextStyles.price),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Prix calculé par Kovoit et figé à la publication du trajet : il ne changera pas après '
            'votre demande. Aucun frais en plus : la commission Kovoit est payée par le conducteur.',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

/// Paiement par le portefeuille : le montant est bloqué à la demande, débité au départ.
/// S'il manque de l'argent, le complément se recharge d'abord par Flooz ou Mixx.
class _WalletPaymentCard extends StatelessWidget {
  const _WalletPaymentCard({required this.payment, required this.onRecharge});

  final PaymentPreview payment;
  final ValueChanged<int> onRecharge;

  @override
  Widget build(BuildContext context) {
    final complement = payment.complementAPayer;
    return KovoitCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined, color: AppColors.accent),
              const SizedBox(width: AppSpacing.xs),
              const Expanded(child: Text('Payé avec mon portefeuille', style: AppTextStyles.cardTitle)),
              Text(Formatters.fcfa(payment.soldeDisponible), style: AppTextStyles.label),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          const Text(
            'Le montant est réservé à la demande, débité seulement à la prise en charge.',
            style: AppTextStyles.caption,
          ),
          if (complement > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            InfoBanner(
              icon: Icons.info_outline_rounded,
              tone: InfoBannerTone.accent,
              title: 'Il manque ${Formatters.fcfa(complement)} sur votre portefeuille.',
            ),
            const SizedBox(height: AppSpacing.sm),
            PrimaryButton(
              label: 'Recharger ${Formatters.fcfa(payment.rechargeSuggeree)}',
              icon: Icons.add_rounded,
              onPressed: () => onRecharge(payment.rechargeSuggeree),
            ),
          ],
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.label, required this.value, this.muted = false});

  final String label;
  final String? value;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final style = muted ? AppTextStyles.caption : AppTextStyles.body;
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        if (value != null) Text(value!, style: style),
      ],
    );
  }
}

class _BookingBar extends StatelessWidget {
  const _BookingBar({required this.label, required this.onPressed, this.isLoading = false});

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.xs, AppSpacing.screenPadding, AppSpacing.sm),
        child: PrimaryButton(label: label, isLoading: isLoading, onPressed: onPressed),
      ),
    );
  }
}
