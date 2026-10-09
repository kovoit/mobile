import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/routes.dart';
import '../../auth/domain/access_policy.dart';
import '../../auth/domain/entities/app_user.dart';
import '../../auth/presentation/providers/session_controller.dart';

/// Bascule passager ↔ conducteur, centralisée dans le Profil (retour UX du 08/10).
/// Vers le mode conducteur : droits KYC + véhicule vérifiés AVANT l'appel ; sinon on affiche
/// la check-list « Devenir conducteur ». Le backend refait le contrôle (403).
Future<void> switchUserMode(BuildContext context, WidgetRef ref, AppUser user) async {
  final target = user.isDriverMode ? UserMode.passager : UserMode.conducteur;
  if (target == UserMode.conducteur && AccessPolicy.canSwitchToDriver(user) != null) {
    await context.push(Routes.becomeDriver);
    return;
  }
  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref.read(sessionControllerProvider.notifier).switchMode(target);
    messenger.showSnackBar(
      SnackBar(
        content: Text(target == UserMode.conducteur ? 'Mode conducteur activé.' : 'Mode passager activé.'),
      ),
    );
    if (context.mounted) context.go(Routes.home);
  } on ApiException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
  }
}
