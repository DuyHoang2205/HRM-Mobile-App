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
        'userv2/login',
        data: {'username': username, 'password': password, 'siteId': siteId},
      );

      _debug('[AuthRepository] Login status: ${response.statusCode}');
      _debug('[AuthRepository] Login raw response: ${response.data}');

      if (response.statusCode == 405) {
        await _probeLegacyLogin(username: username, password: password);
      }

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        _debug('[AuthRepository] Invalid response type: ${data.runtimeType}');
        await _probeLegacyLogin(username: username, password: password);
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
      if (e.response?.statusCode == 405) {
        await _probeLegacyLogin(username: username, password: password);
      }
      _debug(
        '[AuthRepository] Login failed: type=${e.type} status=${e.response?.statusCode} message=${e.message}',
      );
      rethrow;
    } on FormatException {
      rethrow;
    }
  }

  Future<void> _probeLegacyLogin({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _client.dio.get('users/check/$username/$password');
      _debug('[AuthRepository] Legacy login status: ${response.statusCode}');
      _debug(
        '[AuthRepository] Legacy login response type: ${response.data.runtimeType}',
      );
      _debug('[AuthRepository] Legacy login response: ${response.data}');
    } on DioException catch (e) {
      _debug(
        '[AuthRepository] Legacy login probe failed: status=${e.response?.statusCode} message=${e.message}',
      );
    } catch (e) {
      _debug('[AuthRepository] Legacy login probe exception: $e');
    }
  }

  void _debug(String message) {
    if (!kDebugMode) return;
    debugPrint(message);
  }
}
