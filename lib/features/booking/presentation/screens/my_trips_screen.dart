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
import '../../../auth/presentation/providers/session_controller.dart';
import '../../../driver/presentation/providers/driver_providers.dart';
import '../../../driver/presentation/widgets/driver_trip_tile.dart';
import '../../domain/entities/booking.dart';
import '../providers/booking_providers.dart';
import '../widgets/booking_labels.dart';

/// Onglet « Mes trajets » :
/// - mode conducteur : trajets publiés (à venir, terminés), puis ses éventuelles réservations ;
/// - mode passager : réservations (à venir, historique).
class MyTripsScreen extends ConsumerWidget {
  const MyTripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(myBookingsProvider);
    final isDriver = ref.watch(sessionControllerProvider).value?.isDriverMode ?? false;

    return Scaffold(
      appBar: const KovoitAppBar(showBack: false),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(myBookingsProvider.notifier).refresh();
          if (isDriver) await ref.read(myDriverTripsProvider.notifier).refresh();
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            ScreenHeader(
              title: 'Mes trajets',
              subtitle: isDriver ? 'Vos trajets publiés et vos réservations.' : 'Vos réservations et leur statut.',
            ),
            const SizedBox(height: AppSpacing.md),
            if (isDriver) const _PublishedTrips(),
            ...switch (bookings) {
              AsyncValue(:final value?) when value.isEmpty => [if (!isDriver) const _Empty()],
              AsyncValue(:final value?) when isDriver => [
                  const SizedBox(height: AppSpacing.md),
                  const Text('Mes réservations', style: AppTextStyles.title),
                  const SizedBox(height: AppSpacing.xs),
                  ..._sections(context, value),
                ],
              AsyncValue(:final value?) => _sections(context, value),
              AsyncValue(:final error?) => [
                  Text(
                    error is ApiException ? error.message : 'Impossible de charger vos réservations.',
                    style: AppTextStyles.subtitle,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  PrimaryButton.outlined(label: 'Réessayer', onPressed: () => ref.invalidate(myBookingsProvider)),
                ],
              _ => const [Center(child: CircularProgressIndicator())],
            },
          ],
        ),
      ),
    );
  }

  List<Widget> _sections(BuildContext context, List<Booking> bookings) {
    final upcoming = bookings.where((b) => b.status.isUpcoming).toList();
    final past = bookings.where((b) => !b.status.isUpcoming).toList();
    Widget card(Booking b) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _BookingCard(booking: b, onTap: () => context.push(Routes.booking(b.id))),
        );
    return [
      if (upcoming.isNotEmpty) ...[
        const Text('À venir', style: AppTextStyles.title),
        const SizedBox(height: AppSpacing.xs),
        ...upcoming.map(card),
      ],
      if (past.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.sm),
        const Text('Historique', style: AppTextStyles.title),
        const SizedBox(height: AppSpacing.xs),
        ...past.map(card),
      ],
    ];
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, required this.onTap});

  final Booking booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final trip = booking.trip;
    return KovoitCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${Formatters.shortDate(trip.departureAt)} · ${Formatters.time(trip.departureAt)}',
                  style: AppTextStyles.label,
                ),
              ),
              booking.status.chip,
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${trip.depart.displayName} → ${trip.arrivee.displayName}',
            style: AppTextStyles.cardTitle,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            '${trip.driver.nomComplet} · ${trip.vehicle.label} · ${trip.vehicle.immatriculation}',
            style: AppTextStyles.caption,
            overflow: TextOverflow.ellipsis,
          ),
          const Divider(height: AppSpacing.lg),
          Row(
            children: [
              Icon(booking.payment.method.icon, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  '${booking.payment.method.label} · ${booking.payment.status.label}',
                  style: AppTextStyles.caption,
                ),
              ),
              Text(Formatters.fcfa(booking.prixTotal), style: AppTextStyles.label),
            ],
          ),
        ],
      ),
    );
  }
}

/// Trajets publiés par le conducteur.
class _PublishedTrips extends ConsumerWidget {
  const _PublishedTrips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trips = ref.watch(myDriverTripsProvider);
    return switch (trips) {
      AsyncValue(:final value?) when value.isEmpty => const InfoBanner(
          icon: Icons.add_road_rounded,
          tone: InfoBannerTone.accent,
          title: 'Aucun trajet publié',
          subtitle: 'Publiez votre prochain trajet depuis l’onglet « Publier ».',
        ),
      AsyncValue(:final value?) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (title, list) in [
              ('Trajets publiés', value.where((t) => t.status.isUpcoming).toList()),
              ('Trajets passés', value.where((t) => !t.status.isUpcoming).toList()),
            ])
              if (list.isNotEmpty) ...[
                Text(title, style: AppTextStyles.title),
                const SizedBox(height: AppSpacing.xs),
                for (final trip in list) ...[
                  DriverTripTile(trip: trip, onTap: () => context.push(Routes.driverTrip(trip.id))),
                  const SizedBox(height: AppSpacing.xs),
                ],
                const SizedBox(height: AppSpacing.sm),
              ],
          ],
        ),
      AsyncValue(:final error?) => Text(
          error is ApiException ? error.message : 'Impossible de charger vos trajets.',
          style: AppTextStyles.subtitle,
        ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return KovoitCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          const Icon(Icons.route_outlined, size: 40, color: AppColors.textSecondary),
          const SizedBox(height: AppSpacing.sm),
          const Text('Aucune réservation pour l’instant', style: AppTextStyles.cardTitle, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xxs),
          const Text(
            'Trouvez un conducteur qui fait déjà votre trajet.',
            style: AppTextStyles.subtitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(label: 'Rechercher un trajet', icon: Icons.search_rounded, onPressed: () => context.go(Routes.home)),
        ],
      ),
    );
  }
}
