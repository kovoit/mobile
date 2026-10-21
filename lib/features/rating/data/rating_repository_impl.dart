import 'package:dio/dio.dart';

import '../../../core/mock/fake_after_trip.dart';
import '../../../core/network/api_exception.dart';
import '../domain/rating_repository.dart';

/// `POST /reservations/{id}/notes/` (docs/api/after_trip.md).
class DioRatingRepository implements RatingRepository {
  DioRatingRepository(this._dio);

  final Dio _dio;

  @override
  Future<void> rate({required int bookingId, required int note, String? comment}) async {
    try {
      await _dio.post<dynamic>('/reservations/$bookingId/notes/', data: {
        'note': note,
        if (comment != null && comment.trim().isNotEmpty) 'commentaire': comment.trim(),
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

/// Fausse API (`Env.useMockApi`).
class FakeRatingRepository implements RatingRepository {
  FakeRatingRepository(this._fake);

  final FakeAfterTrip _fake;

  @override
  Future<void> rate({required int bookingId, required int note, String? comment}) =>
      _fake.rate(bookingId, note: note, comment: comment?.trim());
}
