import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../dto/auth_response_dto.dart';
import '../dto/otp_challenge_dto.dart';
import '../dto/user_dto.dart';

/// Appels HTTP d'authentification. Toute erreur est levée en [ApiException].
abstract interface class AuthRemoteDataSource {
  Future<AuthResponseDto> login({required String email, required String password});

  Future<AuthResponseDto> register({
    required String nomComplet,
    required String email,
    required String telephone,
    required String password,
  });

  Future<AuthResponseDto> loginWithGoogle(String idToken);

  Future<UserDto> me();

  Future<UserDto> updatePhone(String telephone);

  Future<OtpChallengeDto> sendOtp();

  Future<UserDto> verifyOtp(String code);

  Future<void> requestPasswordReset(String email);

  Future<void> logout(String refreshToken);
}

class DioAuthRemoteDataSource implements AuthRemoteDataSource {
  DioAuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<T> _call<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Map<String, dynamic> _json(Response<dynamic> response) => response.data as Map<String, dynamic>;

  @override
  Future<AuthResponseDto> login({required String email, required String password}) => _call(() async {
        final res = await _dio.post<dynamic>('/auth/login/', data: {'email': email, 'password': password});
        return AuthResponseDto.fromJson(_json(res));
      });

  @override
  Future<AuthResponseDto> register({
    required String nomComplet,
    required String email,
    required String telephone,
    required String password,
  }) =>
      _call(() async {
        final res = await _dio.post<dynamic>('/auth/register/', data: {
          'nom_complet': nomComplet,
          'email': email,
          'telephone': telephone,
          'password': password,
          'cgu_acceptees': true,
        });
        return AuthResponseDto.fromJson(_json(res));
      });

  @override
  Future<AuthResponseDto> loginWithGoogle(String idToken) => _call(() async {
        final res = await _dio.post<dynamic>('/auth/google/', data: {'id_token': idToken});
        return AuthResponseDto.fromJson(_json(res));
      });

  @override
  Future<UserDto> me() => _call(() async {
        final res = await _dio.get<dynamic>('/auth/me/');
        return UserDto.fromJson(_json(res));
      });

  @override
  Future<UserDto> updatePhone(String telephone) => _call(() async {
        final res = await _dio.patch<dynamic>('/auth/me/telephone/', data: {'telephone': telephone});
        return UserDto.fromJson(_json(res));
      });

  @override
  Future<OtpChallengeDto> sendOtp() => _call(() async {
        final res = await _dio.post<dynamic>('/auth/otp/send/');
        return OtpChallengeDto.fromJson(_json(res));
      });

  @override
  Future<UserDto> verifyOtp(String code) => _call(() async {
        final res = await _dio.post<dynamic>('/auth/otp/verify/', data: {'code': code});
        return UserDto.fromJson(_json(res));
      });

  @override
  Future<void> requestPasswordReset(String email) => _call(() async {
        await _dio.post<dynamic>('/auth/password/reset/', data: {'email': email});
      });

  @override
  Future<void> logout(String refreshToken) => _call(() async {
        await _dio.post<dynamic>('/auth/logout/', data: {'refresh': refreshToken});
      });
}
