import 'package:dio/dio.dart';
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
    final response = await _client.dio.post(
      '/UserV2/login',
      data: {'username': username, 'password': password, 'siteId': siteId},
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid login response format');
    }
    final loginResponse = LoginResponse.fromJson(data);
    if (loginResponse.accessToken.isEmpty) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Missing access token',
      );
    }
    return loginResponse;
  }
}
