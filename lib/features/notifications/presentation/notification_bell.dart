import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import 'notifications_providers.dart';

/// Cloche de l'en-tête, avec la pastille orange des notifications non lues.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationsProvider);
    return IconButton(
      onPressed: () => context.push(Routes.notifications),
      tooltip: unread == 0 ? 'Notifications' : 'Notifications : $unread non lue${unread > 1 ? 's' : ''}',
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text(unread > 9 ? '9+' : '$unread'),
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary),
      ),
    );
  }
}
