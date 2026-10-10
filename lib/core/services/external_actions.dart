import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Actions qui sortent de l'application (appel téléphonique, feuille de partage).
/// Derrière une interface pour être simulées dans les tests.
abstract interface class ExternalActions {
  /// `false` si aucun composeur n'est disponible.
  Future<bool> call(String phoneNumber);

  Future<void> share(String text, {String? subject});
}

class PlatformExternalActions implements ExternalActions {
  @override
  Future<bool> call(String phoneNumber) => launchUrl(Uri(scheme: 'tel', path: phoneNumber));

  @override
  Future<void> share(String text, {String? subject}) async {
    await SharePlus.instance.share(ShareParams(text: text, subject: subject));
  }
}

final externalActionsProvider = Provider<ExternalActions>((ref) => PlatformExternalActions());
