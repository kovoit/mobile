import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env.dart';
import '../../../../core/mock/fake_bookings.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/presentation/providers/session_controller.dart';
import '../../data/datasources/booking_remote_data_source.dart';
import '../../data/repositories/booking_repository_impl.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/booking_repository.dart';

final bookingRemoteDataSourceProvider = Provider<BookingRemoteDataSource>((ref) {
  if (Env.useMockApi) return FakeBookingRemoteDataSource(ref.watch(fakeBookingsProvider));
  return DioBookingRemoteDataSource(ref.watch(dioProvider));
});

final bookingRepositoryProvider =
    Provider<BookingRepository>((ref) => BookingRepositoryImpl(ref.watch(bookingRemoteDataSourceProvider)));

/// Réservations du passager (onglet « Mes trajets »).
class MyBookingsController extends AsyncNotifier<List<Booking>> {
  @override
  Future<List<Booking>> build() {
    ref.watch(sessionControllerProvider.select((s) => s.value?.id));
    return ref.read(bookingRepositoryProvider).fetchMine();
  }

  /// Relecture sans repasser par l'état de chargement (tirer pour rafraîchir).
  Future<void> refresh() async {
    state = await AsyncValue.guard(() => ref.read(bookingRepositoryProvider).fetchMine());
  }

  /// Remplace une réservation modifiée ailleurs (suivi, annulation…).
  void upsert(Booking booking) {
    final current = state.value;
    if (current == null) return;
    final exists = current.any((b) => b.id == booking.id);
    state = AsyncData(
      exists ? [for (final b in current) b.id == booking.id ? booking : b] : [booking, ...current],
    );
  }
}

final myBookingsProvider = AsyncNotifierProvider<MyBookingsController, List<Booking>>(MyBookingsController.new);

/// Une réservation suivie à l'écran (« Suivi du trajet & Code de départ »).
class BookingController extends AsyncNotifier<Booking> {
  BookingController(this.bookingId);

  final int bookingId;

  BookingRepository get _repository => ref.read(bookingRepositoryProvider);

  @override
  Future<Booking> build() => _repository.fetch(bookingId);

  void _set(Booking booking) {
    state = AsyncData(booking);
    ref.read(myBookingsProvider.notifier).upsert(booking);
  }

  /// Relecture silencieuse (sondage périodique) : en cas d'erreur réseau, on garde l'affichage.
  Future<void> refresh() async {
    try {
      _set(await _repository.fetch(bookingId));
    } on Object {
      // Le prochain sondage réessaiera.
    }
  }

  Future<Booking> cancel() async {
    final booking = await _repository.cancel(bookingId);
    _set(booking);
    return booking;
  }

  Future<void> pay(String telephone) async => _set(await _repository.pay(bookingId, telephone: telephone));

  Future<ShareLink> shareLink() => _repository.shareLink(bookingId);
}

final bookingProvider = AsyncNotifierProvider.autoDispose.family<BookingController, Booking, int>(BookingController.new);

/// Demande de place depuis « Détails & Réservation ».
class BookingRequester {
  BookingRequester(this._ref);

  final Ref _ref;

  Future<Booking> request({
    required int tripId,
    required int places,
    required int pickupPointId,
    required PaymentMethod method,
  }) async {
    final booking = await _ref
        .read(bookingRepositoryProvider)
        .request(tripId: tripId, places: places, pickupPointId: pickupPointId, method: method);
    _ref.read(myBookingsProvider.notifier).upsert(booking);
    return booking;
  }
}

final bookingRequesterProvider = Provider<BookingRequester>(BookingRequester.new);
