import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/network/dio_client.dart';
import '../models/login_response.dart';

class AuthRepository {
  AuthRepository({DioClient? client}) : _client = client ?? DioClient();
  final DioClient _client;

  Future<LoginResponse> login({
    required String username,
    required String password,
    required String siteId,
  }) async {
    try {
      final response = await _client.dio.post(
        'UserV2/login',
        data: {'username': username, 'password': password, 'siteId': siteId},
      );

      _debug('[AuthRepository] Login status: ${response.statusCode}');

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        _debug('[AuthRepository] Invalid response type: ${data.runtimeType}');
        throw const FormatException('Invalid login response format');
      }
      final loginResponse = LoginResponse.fromJson(data);
      if (loginResponse.accessToken.isEmpty) {
        _debug('[AuthRepository] accessToken is empty');
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Missing access token',
        );
      }
      return loginResponse;
    } on DioException catch (e) {
      _debug(
        '[AuthRepository] Login failed: type=${e.type} status=${e.response?.statusCode} message=${e.message}',
      );
      rethrow;
    }
  }

  void _debug(String message) {
    if (!kDebugMode) return;
    debugPrint(message);
  }
}
