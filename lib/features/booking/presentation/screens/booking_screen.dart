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
import '../../../../core/utils/clock.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/booking.dart';
import '../providers/booking_providers.dart';
import '../widgets/booking_labels.dart';
import '../widgets/departure_code_card.dart';
import '../widgets/payment_card.dart';

/// Maquette « Suivi du trajet & Code de départ ». Le contenu suit le statut renvoyé par l'API,
/// et seules les actions de `booking.actions` sont proposées (claude.md §4).
class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key, required this.bookingId});

  final int bookingId;

  /// Sondage du statut (en attendant les notifications push du sprint S6).
  static const Duration statusPollInterval = Duration(seconds: 15);
  static const Duration paymentPollInterval = Duration(seconds: 3);
  static const Duration paymentPollTimeout = Duration(minutes: 2);

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  Timer? _timer;

  /// Le sondage compte les ticks du minuteur (pas l'horloge murale) : fiable et testable.
  int _ticks = 0;
  int? _paymentPollingStartTick;
  static final int _statusEveryTicks =
      BookingScreen.statusPollInterval.inSeconds ~/ BookingScreen.paymentPollInterval.inSeconds;
  static final int _paymentMaxTicks =
      BookingScreen.paymentPollTimeout.inSeconds ~/ BookingScreen.paymentPollInterval.inSeconds;
  bool _paying = false;
  bool _cancelling = false;
  bool _sharing = false;

  BookingController get _controller => ref.read(bookingProvider(widget.bookingId).notifier);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(BookingScreen.paymentPollInterval, (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Relit la réservation : toutes les 3 s pendant un paiement, toutes les 15 s sinon.
  void _tick() {
    _ticks++;
    final booking = ref.read(bookingProvider(widget.bookingId)).value;
    if (booking == null) return;
    if (booking.payment.status == PaymentStatus.enAttente) {
      _paymentPollingStartTick ??= _ticks;
      if (_ticks - _paymentPollingStartTick! <= _paymentMaxTicks) {
        _controller.refresh();
        return;
      }
    } else {
      _paymentPollingStartTick = null;
    }
    if (booking.status.isUpcoming && _ticks % _statusEveryTicks == 0) _controller.refresh();
  }

  void _snack(String message) =>
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));

  Future<void> _pay(String telephone) async {
    setState(() => _paying = true);
    try {
      await _controller.pay(telephone);
      _paymentPollingStartTick = _ticks;
    } on ApiException catch (e) {
      if (mounted) _snack(e is BadRequestApiException ? (e.fieldErrors['telephone'] ?? e.message) : e.message);
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  Future<void> _cancel(Booking booking) async {
    final now = ref.read(clockProvider)();
    final late = booking.freeCancellationUntil != null && now.isAfter(booking.freeCancellationUntil!);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler cette réservation ?'),
        content: Text(
          late
              ? 'Le départ est proche : cette annulation comptera comme tardive et peut réduire votre fiabilité.'
              : 'Le conducteur sera prévenu et la place sera libérée.',
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
      final until = link.expiresAt == null ? '' : ' (suivi valable jusqu’à ${Formatters.time(link.expiresAt!)})';
      await ref.read(externalActionsProvider).share(
            'Je suis en route avec Kovoit : ${booking.trip.vehicle.label} ${booking.trip.vehicle.immatriculation}, '
            'conduit par ${booking.trip.driver.prenom}. Suivez mon trajet : ${link.url}$until',
            subject: 'Mon trajet Kovoit',
          );
    } on ApiException catch (e) {
      if (mounted) _snack(e.message);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _callDriver(String phone) async {
    final ok = await ref.read(externalActionsProvider).call(phone);
    if (!ok && mounted) _snack('Impossible d’ouvrir le téléphone. Numéro : ${Formatters.phone(phone)}');
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
      _ => ('Votre réservation', '${trip.depart.displayName} → ${trip.arrivee.displayName}'),
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
            vehiclePosition: booking.driverPosition == null
                ? null
                : LatLng(booking.driverPosition!.$1, booking.driverPosition!.$2),
            startLabel: pickup.libelle,
            endLabel: trip.arrivee.displayName.toUpperCase(),
            badge: booking.driverEtaMin == null ? null : '${driver.prenom} · ${booking.driverEtaMin} min',
            tileProvider: ref.watch(mapTileProviderProvider),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (status == BookingStatus.acceptee && booking.driverEtaMin != null) ...[
          InfoBanner(
            icon: Icons.schedule_rounded,
            tone: InfoBannerTone.accent,
            title: '${driver.prenom} arrive dans ${booking.driverEtaMin} min',
            subtitle: pickup.quartier == null ? pickup.libelle : '${pickup.libelle} · ${pickup.quartier}',
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
        if (booking.payment.method.isMobileMoney && status != BookingStatus.refusee) ...[
          PaymentCard(booking: booking, isPaying: _paying, onPay: _pay),
          const SizedBox(height: AppSpacing.md),
        ],
        _DriverSummary(
          booking: booking,
          onCall: booking.can(BookingAction.appeler) && booking.driverPhone != null
              ? () => _callDriver(booking.driverPhone!)
              : null,
        ),
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
          if (booking.freeCancellationUntil != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Annulation gratuite jusqu’à ${Formatters.time(booking.freeCancellationUntil!)}.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption,
            ),
          ],
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
        BookingStatus.demandee => 'Le conducteur doit accepter votre demande · aucune place n’est encore réservée.',
        BookingStatus.acceptee => 'En attente de prise en charge · trajet non démarré.',
        BookingStatus.enCours => 'Trajet démarré : le code de départ a été validé.',
        _ => 'Réservation n° ${booking.id}',
      };
}

class _DriverSummary extends StatelessWidget {
  const _DriverSummary({required this.booking, required this.onCall});

  final Booking booking;
  final VoidCallback? onCall;

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
                        Text('${driver.nbTrajets} trajets', style: AppTextStyles.caption),
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
            '${trip.vehicle.label} · ${trip.vehicle.immatriculation} · ${Formatters.fcfa(booking.prixTotal)} · '
            '${booking.payment.method.label}',
            style: AppTextStyles.caption,
          ),
          if (onCall != null) ...[
            const SizedBox(height: AppSpacing.md),
            PrimaryButton.outlined(label: 'Appeler', icon: Icons.call_outlined, onPressed: onCall),
          ],
        ],
      ),
    );
  }
}

/// Mode démo : joue le rôle du conducteur (accepter, refuser, saisir le code).
class _DemoDriverTools extends ConsumerWidget {
  const _DemoDriverTools({required this.bookingId, required this.onDone});

  final int bookingId;
  final Future<void> Function() onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fake = ref.read(fakeBookingsProvider);
    Widget button(String label, Future<void> Function(int) action) => OutlinedButton(
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
            ],
          ),
        ],
      ),
    );
  }
}
