import '../../../core/constants/api_constants.dart';
import '../../../core/mock/fake_after_trip.dart';
import '../../../core/network/api_service.dart';
import '../domain/report_repository.dart';

/// Texte envoyé au backend : « Retard important — description ».
String reportMotif(ReportReason reason, String description) => '${reason.label} — ${description.trim()}';

/// `POST /reservations/{id}/signalement/` (backend : SignalementEntreeSerializer). Sur un trajet
/// terminé, la réservation passe en litige : le paiement est gelé jusqu'à la décision de l'admin.
class ApiReportRepository implements ReportRepository {
  const ApiReportRepository(this._api);

  final ApiService _api;

  @override
  Future<void> report({required String bookingId, required ReportReason reason, required String description}) =>
      _api.post<void>(
        ApiEndpoints.reservationSignalement(bookingId),
        body: {'motif': reportMotif(reason, description)},
        parse: (_) {},
      );
}

/// Fausse API (`Env.useMockApi`).
class FakeReportRepository implements ReportRepository {
  FakeReportRepository(this._fake);

  final FakeAfterTrip _fake;

  @override
  Future<void> report({required String bookingId, required ReportReason reason, required String description}) =>
      _fake.report(bookingId, motif: reportMotif(reason, description));
}
