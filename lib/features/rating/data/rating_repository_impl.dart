import '../../../core/constants/api_constants.dart';
import '../../../core/mock/fake_after_trip.dart';
import '../../../core/network/api_service.dart';
import '../domain/rating_repository.dart';

/// `POST /reservations/{id}/note/` (backend : NoteEntreeSerializer).
class ApiRatingRepository implements RatingRepository {
  const ApiRatingRepository(this._api);

  final ApiService _api;

  @override
  Future<void> rate({required String bookingId, required int note, String? comment}) => _api.post<void>(
        ApiEndpoints.reservationNote(bookingId),
        body: {'note': note, if (comment != null && comment.trim().isNotEmpty) 'commentaire': comment.trim()},
        parse: (_) {},
      );
}

/// Fausse API (`Env.useMockApi`).
class FakeRatingRepository implements RatingRepository {
  FakeRatingRepository(this._fake);

  final FakeAfterTrip _fake;

  @override
  Future<void> rate({required String bookingId, required int note, String? comment}) =>
      _fake.rate(bookingId, note: note, comment: comment?.trim());
}
