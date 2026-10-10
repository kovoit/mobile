import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kovoit/core/network/api_exception.dart';

DioException _response(int status, [Object? data]) {
  final options = RequestOptions(path: '/test');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(requestOptions: options, statusCode: status, data: data),
  );
}

void main() {
  test('400 DRF : extrait detail et erreurs de champs', () {
    final error = ApiException.fromDio(
      _response(400, {
        'telephone': ['Ce numéro existe déjà.'],
        'non_field_errors': ['Données invalides.'],
      }),
    );
    expect(error, isA<BadRequestApiException>());
    final badRequest = error as BadRequestApiException;
    expect(badRequest.message, 'Données invalides.');
    expect(badRequest.fieldErrors, {'telephone': 'Ce numéro existe déjà.'});
  });

  test('403 utilise le detail renvoyé par le backend', () {
    final error = ApiException.fromDio(_response(403, {'detail': 'KYC passager requis.'}));
    expect(error, isA<ForbiddenApiException>());
    expect(error.message, 'KYC passager requis.');
  });

  test('409 (plus de place) devient ConflictApiException', () {
    expect(ApiException.fromDio(_response(409)), isA<ConflictApiException>());
  });

  test('429 devient TooManyAttemptsApiException', () {
    expect(ApiException.fromDio(_response(429, {'detail': 'Trop d’essais.'})), isA<TooManyAttemptsApiException>());
  });

  test('5xx devient ServerApiException', () {
    expect(ApiException.fromDio(_response(503)), isA<ServerApiException>());
  });

  test('erreur de connexion et timeout', () {
    final options = RequestOptions(path: '/test');
    expect(
      ApiException.fromDio(DioException(requestOptions: options, type: DioExceptionType.connectionError)),
      isA<NetworkApiException>(),
    );
    expect(
      ApiException.fromDio(DioException(requestOptions: options, type: DioExceptionType.receiveTimeout)),
      isA<TimeoutApiException>(),
    );
  });
}
