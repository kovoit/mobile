import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/config/env.dart';
import '../../../../core/mock/fake_bookings.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/services/external_actions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/booking.dart';
import '../providers/booking_providers.dart';
import '../widgets/booking_labels.dart';
import '../widgets/departure_code_card.dart';
import '../../../rating/presentation/rating_sheet.dart';

/// Maquette « Suivi du trajet & Code de départ ». Le contenu suit le statut renvoyé par l'API ;
/// les actions proposées dépendent du statut et le backend refuse celles devenues impossibles.
class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key, required this.bookingId});

  final String bookingId;

  /// Relecture du statut (en complément des notifications push et email).
  static const Duration statusPollInterval = Duration(seconds: 15);

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  Timer? _timer;
  bool _cancelling = false;
  bool _sharing = false;
  bool _confirming = false;

  BookingController get _controller => ref.read(bookingProvider(widget.bookingId).notifier);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(BookingScreen.statusPollInterval, (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Relit la réservation tant qu'elle est en cours de vie.
  void _tick() {
    final booking = ref.read(bookingProvider(widget.bookingId)).value;
    if (booking != null && booking.status.isUpcoming) _controller.refresh();
  }

  void _snack(String message) =>
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));

  Future<void> _cancel(Booking booking) async {
    final accepted = booking.status == BookingStatus.acceptee;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler cette réservation ?'),
        content: Text(
          accepted
              ? 'Le conducteur sera prévenu et la place libérée. Si le départ est proche, '
                  'l’annulation compte comme tardive et peut réduire votre fiabilité.'
              : 'Le conducteur sera prévenu et le montant réservé vous sera rendu.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Garder ma place')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Annuler la réservation'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _cancelling = true);
    try {
      final cancelled = await _controller.cancel();
      if (mounted) {
        _snack(cancelled.lateCancellation ? 'Réservation annulée (annulation tardive).' : 'Réservation annulée.');
      }
    } on ApiException catch (e) {
      if (mounted) _snack(e.message);
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  Future<void> _share(Booking booking) async {
    setState(() => _sharing = true);
    try {
      final link = await _controller.shareLink();
      await ref.read(externalActionsProvider).share(
            'Je suis en route avec Kovoit : ${booking.trip.vehicle.label} ${booking.trip.vehicle.immatriculation}, '
            'conduit par ${booking.trip.driver.prenom}. Suivez mon trajet : ${link.url}',
            subject: 'Mon trajet Kovoit',
          );
    } on ApiException catch (e) {
      if (mounted) _snack(e.message);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  /// CA8 : confirmation d'arrivée, puis invitation à noter le conducteur.
  Future<void> _confirmArrival(Booking booking) async {
    setState(() => _confirming = true);
    try {
      final closed = await _controller.confirmArrival();
      if (!mounted) return;
      _snack('Arrivée confirmée. Merci !');
      if (closed.can(BookingAction.noter) && !ref.read(ratedBookingsProvider).contains(closed.id)) await _rate(closed);
    } on ApiException catch (e) {
      if (mounted) _snack(e.message);
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  Future<void> _rate(Booking booking) async {
    final rated = await RatingSheet.show(context, bookingId: booking.id, personName: booking.trip.driver.prenom);
    if (rated == true) {
      await _controller.refresh();
      if (mounted) _snack('Merci pour votre note !');
    }
  }

  Future<void> _report(Booking booking) async {
    final sent = await context.push<bool>(Routes.report(booking.id, otherName: booking.trip.driver.prenom));
    if (sent == true) await _controller.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final booking = ref.watch(bookingProvider(widget.bookingId));

    return Scaffold(
      appBar: KovoitAppBar(onBack: () => context.canPop() ? context.pop() : context.go(Routes.myTrips)),
      body: switch (booking) {
        AsyncValue(:final value?) => RefreshIndicator(
            onRefresh: _controller.refresh,
            child: _content(value),
          ),
        AsyncValue(:final error?) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    error is ApiException ? error.message : 'Impossible de charger la réservation.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PrimaryButton.outlined(
                    label: 'Réessayer',
                    onPressed: () => ref.invalidate(bookingProvider(widget.bookingId)),
                  ),
                ],
              ),
            ),
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  Widget _content(Booking booking) {
    final trip = booking.trip;
    final driver = trip.driver;
    final pickup = booking.pickupPoint?.place ?? trip.depart;
    final status = booking.status;
    final showMap = status == BookingStatus.acceptee || status == BookingStatus.enCours;

    final (title, subtitle) = switch (status) {
      BookingStatus.demandee => ('Demande envoyée', 'En attente de la réponse de ${driver.prenom}.'),
      BookingStatus.acceptee => ('Suivi du trajet & Code de départ', 'Votre conducteur arrive au point de rencontre.'),
      BookingStatus.enCours => ('Trajet en cours', 'Bon voyage avec ${driver.prenom} !'),
      BookingStatus.refusee => ('Demande refusée', '${driver.prenom} ne peut pas vous prendre sur ce trajet.'),
      BookingStatus.annulee => ('Réservation annulée', booking.lateCancellation ? 'Annulation tardive.' : 'La place a été libérée.'),
      BookingStatus.terminee => ('Vous êtes arrivé ?', 'Confirmez votre arrivée avec ${driver.prenom}.'),
      BookingStatus.cloturee => ('Trajet terminé', 'Merci d’avoir voyagé avec Kovoit.'),
      BookingStatus.litige => ('Signalement en cours', 'Un administrateur examine la situation.'),
      BookingStatus.absent => ('Absence déclarée', '${driver.prenom} ne vous a pas trouvé au point de prise en charge.'),
    };

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        ScreenHeader(title: title, subtitle: subtitle),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xxs,
          children: [
            status.chip,
            StatusChip(
              label: '${Formatters.shortDate(trip.departureAt)} · ${Formatters.time(trip.departureAt)}',
              tone: StatusTone.info,
              icon: Icons.schedule_rounded,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (showMap) ...[
          MapPreview(
            start: LatLng(pickup.lat, pickup.lng),
            end: LatLng(trip.arrivee.lat, trip.arrivee.lng),
            route: const [],
            startLabel: pickup.libelle,
            endLabel: trip.arrivee.displayName.toUpperCase(),
            tileProvider: ref.watch(mapTileProviderProvider),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (status == BookingStatus.demandee) ...[
          InfoBanner(
            icon: Icons.hourglass_top_rounded,
            tone: InfoBannerTone.accent,
            title: 'Prise en charge prévue à ${Formatters.time(trip.departureAt)}',
            subtitle: pickup.quartier == null ? pickup.libelle : '${pickup.libelle} · ${pickup.quartier}',
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (booking.departureCode != null) ...[
          DepartureCodeCard(code: booking.departureCode!),
          const SizedBox(height: AppSpacing.md),
        ],
        _DriverSummary(booking: booking),
        if (booking.can(BookingAction.partager)) ...[
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: TextButton.icon(
              onPressed: _sharing ? null : () => _share(booking),
              icon: const Icon(Icons.share_outlined, color: AppColors.textPrimary),
              label: Text('Partager mon trajet', style: AppTextStyles.label.copyWith(color: AppColors.textPrimary)),
            ),
          ),
        ],
        if (status == BookingStatus.litige) ...[
          const SizedBox(height: AppSpacing.md),
          const InfoBanner(
            icon: Icons.gavel_rounded,
            tone: InfoBannerTone.accent,
            title: 'Votre signalement est en cours d’examen',
            subtitle: 'Le paiement est gelé jusqu’à la décision de l’administrateur.',
          ),
        ],
        if (booking.can(BookingAction.confirmer)) ...[
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: 'Confirmer mon arrivée',
            icon: Icons.check_circle_outline_rounded,
            isLoading: _confirming,
            onPressed: () => _confirmArrival(booking),
          ),
        ],
        if (booking.can(BookingAction.noter) && !ref.watch(ratedBookingsProvider).contains(booking.id)) ...[
          const SizedBox(height: AppSpacing.sm),
          PrimaryButton.outlined(
            label: 'Noter ${driver.prenom}',
            icon: Icons.star_outline_rounded,
            onPressed: () => _rate(booking),
          ),
        ],
        if (booking.can(BookingAction.signaler)) ...[
          const SizedBox(height: AppSpacing.xs),
          Center(
            child: TextButton.icon(
              onPressed: () => _report(booking),
              icon: const Icon(Icons.report_gmailerrorred_rounded, color: AppColors.error),
              label: Text('Signaler un problème', style: AppTextStyles.label.copyWith(color: AppColors.error)),
            ),
          ),
        ],
        if (status == BookingStatus.refusee || status == BookingStatus.annulee) ...[
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: 'Rechercher un autre trajet',
            icon: Icons.search_rounded,
            onPressed: () => context.go(Routes.home),
          ),
        ],
        if (booking.can(BookingAction.annuler)) ...[
          const SizedBox(height: AppSpacing.sm),
          PrimaryButton.outlined(label: 'Annuler', isLoading: _cancelling, onPressed: () => _cancel(booking)),
        ],
        const SizedBox(height: AppSpacing.sm),
        Text(_footer(booking), textAlign: TextAlign.center, style: AppTextStyles.caption),
        if (Env.useMockApi && status.isUpcoming) ...[
          const SizedBox(height: AppSpacing.lg),
          _DemoDriverTools(bookingId: booking.id, onDone: _controller.refresh),
        ],
      ],
    );
  }

  String _footer(Booking booking) => switch (booking.status) {
        BookingStatus.demandee => 'Le conducteur doit accepter votre demande · le montant est réservé sur votre portefeuille.',
        BookingStatus.acceptee => 'En attente de prise en charge · trajet non démarré.',
        BookingStatus.enCours => 'Trajet démarré : le code de départ a été validé.',
        BookingStatus.terminee => 'Sans réponse de votre part, le trajet sera clôturé automatiquement.',
        _ => 'Réservation n° ${booking.id}',
      };
}

class _DriverSummary extends StatelessWidget {
  const _DriverSummary({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final trip = booking.trip;
    final driver = trip.driver;
    return KovoitCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UserAvatar(name: driver.nomComplet, photoUrl: driver.photoUrl, size: 48),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(driver.nomComplet, style: AppTextStyles.cardTitle),
                    const SizedBox(height: AppSpacing.xxs),
                    Wrap(
                      spacing: AppSpacing.xs,
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
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${trip.vehicle.label} · ${trip.vehicle.immatriculation} · ${Formatters.fcfa(booking.montantTotal)} · '
            'portefeuille',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

/// Mode démo : joue le rôle du conducteur (accepter, refuser, saisir le code).
class _DemoDriverTools extends ConsumerWidget {
  const _DemoDriverTools({required this.bookingId, required this.onDone});

  final String bookingId;
  final Future<void> Function() onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fake = ref.read(fakeBookingsProvider);
    Widget button(String label, Future<void> Function(String) action) => OutlinedButton(
          onPressed: () async {
            await action(bookingId);
            await onDone();
          },
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
          child: Text(label),
        );

    return KovoitCard(
      color: AppColors.accentLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Mode démo · simuler le conducteur', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              button('Accepter', fake.simulateDriverAccepts),
              button('Refuser', fake.simulateDriverRefuses),
              button('Saisir le code', fake.simulatePickup),
              button('Terminer le trajet', fake.simulateTripFinished),
            ],
          ),
        ],
      ),
    );
  }
}
