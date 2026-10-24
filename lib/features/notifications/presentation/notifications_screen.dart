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
import '../../auth/presentation/providers/session_controller.dart';
import '../domain/app_notification.dart';
import 'notifications_providers.dart';
import 'push_coordinator.dart';

/// Notifications reçues (aussi celles dont le push n'est jamais arrivé). Toucher une
/// notification la marque comme lue et ouvre l'écran concerné, comme le push.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _open(BuildContext context, WidgetRef ref, AppNotification n) async {
    final source = ref.read(notificationsRemoteDataSourceProvider);
    if (!n.lue) {
      try {
        await source.markRead(n.id);
      } on ApiException {
        // Rien de bloquant : elle restera non lue.
      }
      ref
        ..invalidate(notificationsProvider)
        ..invalidate(unreadNotificationsProvider);
    }
    if (!context.mounted || n.donnees.isEmpty) return;
    final driverMode = ref.read(sessionControllerProvider).value?.isDriverMode ?? false;
    await context.push(pushRoute(data: n.donnees, driverMode: driverMode));
  }

  Future<void> _markAll(WidgetRef ref) async {
    await ref.read(notificationsRemoteDataSourceProvider).markAllRead();
    ref
      ..invalidate(notificationsProvider)
      ..invalidate(unreadNotificationsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final now = ref.watch(clockProvider)();
    final hasUnread = notifications.value?.any((n) => !n.lue) ?? false;
    return Scaffold(
      appBar: KovoitAppBar(onBack: () => context.pop()),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(notificationsProvider),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            const ScreenHeader(title: 'Notifications', subtitle: 'Réservations, trajets et paiements.'),
            if (hasUnread)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: () => _markAll(ref), child: const Text('Tout marquer comme lu')),
              ),
            const SizedBox(height: AppSpacing.sm),
            switch (notifications) {
              AsyncValue(:final value?) when value.isEmpty => const InfoBanner(
                  icon: Icons.notifications_none_rounded,
                  tone: InfoBannerTone.accent,
                  title: 'Aucune notification',
                  subtitle: 'Vous serez prévenu ici de chaque étape de vos trajets.',
                ),
              AsyncValue(:final value?) => Column(
                  children: [
                    for (final n in value)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _NotificationTile(
                          notification: n,
                          when: Formatters.relative(n.creeLe, now: now),
                          onTap: () => _open(context, ref, n),
                        ),
                      ),
                  ],
                ),
              AsyncValue(:final error?) => InfoBanner(
                  icon: Icons.error_outline_rounded,
                  tone: InfoBannerTone.error,
                  title: 'Notifications indisponibles',
                  subtitle: error is ApiException ? error.message : 'Vérifiez votre connexion puis réessayez.',
                ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.when, required this.onTap});

  final AppNotification notification;
  final String when;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final n = notification;
    return KovoitCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, right: AppSpacing.sm),
            child: CircleAvatar(radius: 4, backgroundColor: n.lue ? Colors.transparent : AppColors.accent),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(n.titre, style: n.lue ? AppTextStyles.body : AppTextStyles.cardTitle),
                const SizedBox(height: AppSpacing.xxs),
                Text(n.message, style: AppTextStyles.body),
                const SizedBox(height: AppSpacing.xxs),
                Text(when, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
