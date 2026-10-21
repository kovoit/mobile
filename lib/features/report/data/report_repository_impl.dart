import 'package:dio/dio.dart';

import '../../../core/mock/fake_after_trip.dart';
import '../../../core/network/api_exception.dart';
import '../domain/report_repository.dart';

/// `POST /signalements/` (docs/api/after_trip.md).
class DioReportRepository implements ReportRepository {
  DioReportRepository(this._dio);

  final Dio _dio;

  @override
  Future<void> report({required int bookingId, required ReportReason reason, required String description}) async {
    try {
      await _dio.post<dynamic>('/signalements/', data: {
        'reservation_id': bookingId,
        'motif': reason.apiValue,
        'description': description.trim(),
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

/// Fausse API (`Env.useMockApi`).
class FakeReportRepository implements ReportRepository {
  FakeReportRepository(this._fake);

  final FakeAfterTrip _fake;

  @override
  Future<void> report({required int bookingId, required ReportReason reason, required String description}) =>
      _fake.report(bookingId, reason: reason.apiValue, description: description.trim());
}
