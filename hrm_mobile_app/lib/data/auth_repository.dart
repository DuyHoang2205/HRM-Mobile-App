import '../../../core/network/dio_client.dart';

class AuthRepository {
  final DioClient _client = DioClient();

  Future<String> login(String username, String password) async {
    // Hits @Post('login') in Userv2Controller
    final response = await _client.dio.post('/UserV2/login', data: {
      'username': username,
      'password': password,
    });
    return response.data['accessToken']; //
  }
}