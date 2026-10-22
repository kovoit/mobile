import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_exception.dart';
import 'fake_backend.dart';

final fakeAfterTripProvider = Provider<FakeAfterTrip>((ref) => FakeAfterTrip(ref.watch(fakeBackendProvider)));

/// Règles **serveur** simulées de l'après-trajet (notes, signalements) et de l'enregistrement
/// des appareils pour le push. Jamais utilisé avec le vrai backend.
///
/// La fausse API sépare les réservations des passagers et les demandes reçues par les
/// conducteurs : une note ou un signalement retrouve la réservation dans l'une ou l'autre.
class FakeAfterTrip {
  FakeAfterTrip(this._backend);

  final FakeBackend _backend;

  static const notables = {'terminee', 'litige', 'cloturee'};
  static const signalables = {'en_cours', 'terminee', 'litige', 'cloturee', 'absent'};

  /// Statut et rôle de l'appelant pour une réservation, ou 404.
  Future<({int authorId, Map<String, dynamic> booking})> _find(String bookingId) async {
    final userId = await _backend.currentUserId();
    final asPassenger = _backend.bookings[bookingId];
    if (asPassenger != null && asPassenger['passager_id'] == userId) return (authorId: userId, booking: asPassenger);
    for (final trip in _backend.driverTrips.values.where((t) => t['conducteur_id'] == userId)) {
      for (final request in (trip['demandes'] as List).cast<Map<String, dynamic>>()) {
        if (request['id'] == bookingId) return (authorId: userId, booking: request);
      }
    }
    throw const NotFoundApiException('Réservation introuvable.');
  }

  /// `POST /reservations/{id}/note/`.
  Future<void> rate(String bookingId, {required int note, String? comment}) async {
    await _backend.wait();
    final (:authorId, :booking) = await _find(bookingId);
    if (note < 1 || note > 5) {
      throw const BadRequestApiException('Les données envoyées sont invalides.',
          code: 'DONNEES_INVALIDES', fieldErrors: {'note': 'Choisissez entre 1 et 5 étoiles.'});
    }
    if (!notables.contains(booking['statut'])) {
      throw const ConflictApiException('La note est possible après le trajet.', code: 'NOTE_PREMATUREE');
    }
    if (!_backend.ratings.add('$bookingId:$authorId')) {
      throw const ConflictApiException('Vous avez déjà noté ce trajet.', code: 'DEJA_NOTE');
    }
  }

  /// `POST /reservations/{id}/signalement/` : sur un trajet terminé, la réservation passe en litige.
  Future<void> report(String bookingId, {required String motif}) async {
    await _backend.wait();
    final (:authorId, :booking) = await _find(bookingId);
    if (motif.trim().isEmpty) {
      throw const BadRequestApiException('Les données envoyées sont invalides.',
          code: 'DONNEES_INVALIDES', fieldErrors: {'motif': 'Décrivez le problème.'});
    }
    if (!signalables.contains(booking['statut'])) {
      throw const ConflictApiException('Signalement possible pendant ou après le trajet.', code: 'SIGNALEMENT_IMPOSSIBLE');
    }
    _backend.reports['$bookingId:$authorId'] = motif;
    if (booking['statut'] == 'terminee') booking['statut'] = 'litige';
  }

  /// `POST /notifications/appareils/`.
  Future<void> registerDevice(String token) async {
    await _backend.wait();
    _backend.devices[token] = await _backend.currentUserId();
  }

  /// `DELETE /notifications/appareils/{jeton}/`.
  Future<void> unregisterDevice(String token) async {
    await _backend.wait();
    _backend.devices.remove(token);
  }
}
