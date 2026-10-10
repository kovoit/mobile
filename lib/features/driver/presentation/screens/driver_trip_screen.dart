import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/driver_trip.dart';
import '../providers/driver_providers.dart';
import '../widgets/departure_code_dialog.dart';
import '../widgets/driver_trip_labels.dart';
import '../widgets/request_card.dart';

/// Gestion d'un trajet publié : demandes reçues (CA3/CA4), code de départ (CA7),
/// absence (CA9), fin et annulation du trajet. Seules les actions renvoyées par l'API sont proposées.
class DriverTripScreen extends ConsumerStatefulWidget {
  const DriverTripScreen({super.key, required this.tripId});

  final int tripId;

  /// Sondage des nouvelles demandes, en attendant les notifications push (S6).
  static const Duration pollInterval = Duration(seconds: 15);

  @override
  ConsumerState<DriverTripScreen> createState() => _DriverTripScreenState();
}

class _DriverTripScreenState extends ConsumerState<DriverTripScreen> {
  Timer? _timer;
  int? _busyRequestId;
  bool _busyTrip = false;

  DriverTripController get _controller => ref.read(driverTripProvider(widget.tripId).notifier);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(DriverTripScreen.pollInterval, (_) {
      final trip = ref.read(driverTripProvider(widget.tripId)).value;
      if (trip != null && trip.status.isUpcoming) _controller.refresh();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _snack(String message) =>
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));

  Future<void> _onRequest(DriverRequest request, Future<void> Function() action, {String? success}) async {
    setState(() => _busyRequestId = request.id);
    try {
      await action();
      if (success != null && mounted) _snack(success);
    } on ApiException catch (e) {
      if (mounted) _snack(e.message);
      await _controller.refresh();
    } finally {
      if (mounted) setState(() => _busyRequestId = null);
    }
  }

  Future<void> _enterCode(DriverRequest request) async {
    final ok = await DepartureCodeDialog.show(
      context,
      passengerName: request.passenger.prenom,
      onSubmit: (code) => _controller.submitCode(request.id, code),
    );
    if (ok == true && mounted) _snack('${request.passenger.prenom} est à bord. Bon trajet !');
  }

  Future<void> _declareAbsence(DriverRequest request) async {
    final confirmed = await _confirm(
      title: 'Déclarer ${request.passenger.prenom} absent ?',
      body: 'Votre position actuelle sera enregistrée comme preuve que vous étiez au point de prise en charge. '
          'Le passager devra régler le trajet.',
      confirmLabel: 'Déclarer absent',
    );
    if (!confirmed) return;
    setState(() => _busyRequestId = request.id);
    final position = await ref.read(locationServiceProvider).currentPosition();
    if (!mounted) return;
    switch (position) {
      case LocationUnavailable(:final message):
        setState(() => _busyRequestId = null);
        _snack(message);
      case LocationFound(:final lat, :final lng):
        await _onRequest(
          request,
          () => _controller.declareAbsence(request.id, lat: lat, lng: lng),
          success: 'Absence enregistrée.',
        );
    }
  }

  Future<void> _tripAction(Future<void> Function() action, String success) async {
    setState(() => _busyTrip = true);
    try {
      await action();
      if (mounted) _snack(success);
    } on ApiException catch (e) {
      if (mounted) _snack(e.message);
    } finally {
      if (mounted) setState(() => _busyTrip = false);
    }
  }

  Future<bool> _confirm({required String title, required String body, required String confirmLabel}) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Retour')),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: Text(confirmLabel),
            ),
          ],
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final trip = ref.watch(driverTripProvider(widget.tripId));
    return Scaffold(
      appBar: KovoitAppBar(onBack: () => context.canPop() ? context.pop() : context.go(Routes.myTrips)),
      body: switch (trip) {
        AsyncValue(:final value?) => RefreshIndicator(onRefresh: _controller.refresh, child: _content(value)),
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
                    onPressed: () => ref.invalidate(driverTripProvider(widget.tripId)),
                  ),
                ],
              ),
            ),
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  Widget _content(DriverTrip trip) {
    final active = trip.requests.where((r) => r.status.isUpcoming).toList();
    final others = trip.requests.where((r) => !r.status.isUpcoming).toList();

    Widget card(DriverRequest r) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: RequestCard(
            request: r,
            pickup: trip.pickupFor(r),
            busy: _busyRequestId == r.id,
            onAccept: () => _onRequest(r, () => _controller.accept(r.id), success: 'Demande acceptée.'),
            onRefuse: () => _onRequest(r, () => _controller.refuse(r.id), success: 'Demande refusée.'),
            onEnterCode: () => _enterCode(r),
            onDeclareAbsence: () => _declareAbsence(r),
          ),
        );

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        ScreenHeader(
          title: 'Mon trajet',
          subtitle: '${Formatters.longDate(trip.departureAt)} · ${Formatters.time(trip.departureAt)}',
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xxs,
          children: [
            trip.status.chip,
            StatusChip(
              label: '${trip.placesRestantes}/${trip.placesTotal} places libres',
              tone: StatusTone.info,
              icon: Icons.event_seat_outlined,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _TripSummary(trip: trip),
        const SizedBox(height: AppSpacing.lg),
        const Text('Demandes reçues', style: AppTextStyles.title),
        const SizedBox(height: AppSpacing.xs),
        if (trip.requests.isEmpty)
          const InfoBanner(
            icon: Icons.hourglass_empty_rounded,
            tone: InfoBannerTone.accent,
            title: 'Aucune demande pour l’instant',
            subtitle: 'Les passagers proches de vos carrefours peuvent trouver votre trajet.',
          ),
        ...active.map(card),
        if (others.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          const Text('Demandes traitées', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.xs),
          ...others.map(card),
        ],
        if (trip.can(DriverTripAction.terminer)) ...[
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: 'Terminer le trajet',
            icon: Icons.flag_outlined,
            isLoading: _busyTrip,
            onPressed: () => _tripAction(_controller.finish, 'Trajet terminé. Merci !'),
          ),
        ],
        if (trip.can(DriverTripAction.annuler)) ...[
          const SizedBox(height: AppSpacing.sm),
          PrimaryButton.outlined(
            label: 'Annuler le trajet',
            isLoading: _busyTrip,
            onPressed: () async {
              final confirmed = await _confirm(
                title: 'Annuler ce trajet ?',
                body: 'Les passagers seront prévenus et remboursés. Une annulation proche du départ '
                    'compte comme tardive pour votre fiabilité.',
                confirmLabel: 'Annuler le trajet',
              );
              if (confirmed) await _tripAction(_controller.cancel, 'Trajet annulé.');
            },
          ),
        ],
      ],
    );
  }
}

class _TripSummary extends StatelessWidget {
  const _TripSummary({required this.trip});

  final DriverTrip trip;

  @override
  Widget build(BuildContext context) {
    return KovoitCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${trip.depart.displayName} → ${trip.arrivee.displayName}', style: AppTextStyles.cardTitle),
          const SizedBox(height: AppSpacing.xs),
          for (final point in trip.pickupPoints)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: AppColors.accentLight,
                    child: Text('${point.ordre}', style: AppTextStyles.caption.copyWith(color: AppColors.warning)),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(child: Text(point.place.libelle, style: AppTextStyles.body)),
                ],
              ),
            ),
          const Divider(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Text('${Formatters.fcfa(trip.prixPlace)} par place', style: AppTextStyles.label),
              ),
              if (trip.economie > 0)
                Text(
                  'Économie : ${Formatters.fcfa(trip.economie)}',
                  style: AppTextStyles.label.copyWith(color: AppColors.success),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
