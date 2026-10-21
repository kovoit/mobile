import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/app_notification.dart';
import 'notifications_providers.dart';
import 'push_coordinator.dart';

/// Liste des notifications (changements de statut). Toucher une ligne ouvre l'écran concerné.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _open(BuildContext context, WidgetRef ref, AppNotification n) async {
    await ref.read(notificationsProvider.notifier).markRead(n);
    final route = notificationRoute(bookingId: n.bookingId, tripId: n.tripId, type: n.type);
    if (route != null && context.mounted) await context.push(route);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final unread = ref.watch(unreadNotificationsProvider);
    final now = ref.read(clockProvider)();

    return Scaffold(
      appBar: const KovoitAppBar(),
      body: RefreshIndicator(
        onRefresh: ref.read(notificationsProvider.notifier).refresh,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Expanded(
                  child: ScreenHeader(title: 'Notifications', subtitle: 'Vos réservations et trajets en direct.'),
                ),
                if (unread > 0)
                  TextButton(
                    onPressed: ref.read(notificationsProvider.notifier).markAllRead,
                    child: const Text('Tout lire'),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ...switch (notifications) {
              AsyncValue(:final value?) when value.isEmpty => [
                  const InfoBanner(
                    icon: Icons.notifications_none_rounded,
                    tone: InfoBannerTone.accent,
                    title: 'Aucune notification',
                    subtitle: 'Vous serez prévenu ici de chaque réponse, prise en charge ou paiement.',
                  ),
                ],
              AsyncValue(:final value?) => [
                  for (final n in value) ...[
                    _NotificationTile(notification: n, now: now, onTap: () => _open(context, ref, n)),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                ],
              AsyncValue(:final error?) => [
                  Text(
                    error is ApiException ? error.message : 'Impossible de charger vos notifications.',
                    style: AppTextStyles.subtitle,
                  ),
                ],
              _ => const [Center(child: CircularProgressIndicator())],
            },
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.now, required this.onTap});

  final AppNotification notification;
  final DateTime now;
  final VoidCallback onTap;

  IconData get _icon => switch (notification.type) {
        'nouvelle_demande' => Icons.person_add_alt_1_outlined,
        'reservation_acceptee' => Icons.check_circle_outline_rounded,
        'reservation_refusee' || 'reservation_annulee' => Icons.cancel_outlined,
        'prise_en_charge' => Icons.directions_car_filled_outlined,
        'trajet_termine' => Icons.flag_outlined,
        'paiement_reussi' || 'remboursement' => Icons.payments_outlined,
        'paiement_echoue' => Icons.error_outline_rounded,
        'kyc_valide' || 'kyc_refuse' => Icons.verified_user_outlined,
        _ => Icons.notifications_none_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final unread = !notification.read;
    return KovoitCard(
      onTap: onTap,
      color: unread ? AppColors.accentLight : AppColors.surface,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Badge(
            isLabelVisible: unread,
            smallSize: 10,
            backgroundColor: AppColors.accent,
            child: CircleAvatar(
              backgroundColor: AppColors.fieldFill,
              child: Icon(_icon, color: AppColors.textPrimary, size: 20),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: AppTextStyles.label.copyWith(fontWeight: unread ? FontWeight.w700 : FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(notification.message, style: AppTextStyles.caption),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  Formatters.relative(notification.createdAt, now: now),
                  style: AppTextStyles.caption.copyWith(color: AppColors.textDisabled),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
