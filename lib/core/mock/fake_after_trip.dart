import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_exception.dart';
import 'fake_backend.dart';

final fakeAfterTripProvider = Provider<FakeAfterTrip>((ref) => FakeAfterTrip(ref.watch(fakeBackendProvider)));

/// Règles **serveur** simulées de l'après-trajet (notes, signalements) et des notifications
/// (docs/api/after_trip.md). Jamais utilisé avec le vrai backend.
///
/// La fausse API sépare les réservations des passagers (501…) et les demandes reçues par les
/// conducteurs (801…) : une note ou un signalement retrouve la réservation dans l'un ou l'autre.
class FakeAfterTrip {
  FakeAfterTrip(this._backend);

  final FakeBackend _backend;

  static const List<String> reasons = ['retard', 'comportement', 'securite', 'vehicule', 'paiement', 'autre'];

  /// Statut et rôle de l'appelant pour une réservation, ou 404.
  Future<({int authorId, Map<String, dynamic> booking})> _find(int bookingId) async {
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

  Future<void> rate(int bookingId, {required int note, String? comment}) async {
    await _backend.wait();
    final (:authorId, :booking) = await _find(bookingId);
    final key = '$bookingId:$authorId';
    if (note < 1 || note > 5) {
      throw const BadRequestApiException('Note invalide.', fieldErrors: {'note': 'Choisissez entre 1 et 5 étoiles.'});
    }
    if ((comment?.length ?? 0) > 300) {
      throw const BadRequestApiException('Commentaire trop long.', fieldErrors: {'commentaire': '300 caractères maximum.'});
    }
    if (!['terminee', 'cloturee', 'absent'].contains(booking['statut'])) {
      throw const ConflictApiException('Vous pourrez noter ce trajet une fois terminé.');
    }
    if (!_backend.ratings.add(key)) throw const ConflictApiException('Vous avez déjà noté ce trajet.');
  }

  Future<Map<String, dynamic>> report(int bookingId, {required String reason, required String description}) async {
    await _backend.wait();
    final (:authorId, :booking) = await _find(bookingId);
    final key = '$bookingId:$authorId';
    if (!reasons.contains(reason)) throw const BadRequestApiException('Motif invalide.', fieldErrors: {'motif': 'Motif invalide.'});
    if (description.trim().isEmpty) {
      throw const BadRequestApiException('Décrivez le problème.', fieldErrors: {'description': 'Décrivez le problème.'});
    }
    if (_backend.reports.containsKey(key)) throw const ConflictApiException('Vous avez déjà signalé ce trajet.');
    _backend.reports[key] = reason;
    // Signalement après le trajet : la réservation passe en litige, le paiement est gelé.
    if (booking['statut'] == 'terminee') booking['statut'] = 'litige';
    return {'id': _backend.reports.length, 'statut': 'ouvert'};
  }

  Future<List<Map<String, dynamic>>> notifications() async {
    await _backend.wait();
    final userId = await _backend.currentUserId();
    return [for (final n in (_backend.notifications[userId] ?? const <Map<String, dynamic>>[]).take(50)) Map.of(n)];
  }

  Future<void> markRead(List<int>? ids) async {
    await _backend.wait();
    final userId = await _backend.currentUserId();
    for (final n in _backend.notifications[userId] ?? const <Map<String, dynamic>>[]) {
      if (ids == null || ids.contains(n['id'])) n['lue'] = true;
    }
  }

  Future<void> registerDevice(String token) async {
    await _backend.wait();
    _backend.devices[token] = await _backend.currentUserId();
  }

  Future<void> unregisterDevice(String token) async {
    await _backend.wait();
    _backend.devices.remove(token);
  }
}
