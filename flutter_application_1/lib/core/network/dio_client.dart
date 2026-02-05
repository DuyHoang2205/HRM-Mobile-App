import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DioClient {
  late final Dio dio;

  DioClient() {
    dio = Dio(BaseOptions(baseUrl: 'http://localhost:3003/api/'));
    // dio = Dio(BaseOptions(baseUrl: 'http://192.168.10.14:3003/api/'));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('access_token');
        
        if (token != null) {
          // Attach token to pass JwtAuthGuard
          options.headers['Authorization'] = 'Bearer $token'; 
        }
        return handler.next(options);
      },
    ));
  }
}