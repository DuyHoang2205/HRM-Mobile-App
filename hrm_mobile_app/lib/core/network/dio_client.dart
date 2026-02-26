import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../core/auth/auth_helper.dart';

class DioClient {
  late final Dio dio;

  DioClient() {
    dio = Dio(BaseOptions(
      baseUrl: 'http://vpn.dptsolution.net:853/hrm/api/',
      validateStatus: (status) => status! < 500,
      contentType: 'application/json; charset=utf-8',
    ));

    dio.interceptors.add(QueuedInterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await AuthHelper.getAccessToken();
        
        if (token != null) {
          // Attach token to pass JwtAuthGuard
          options.headers['Authorization'] = 'Bearer $token'; 
        }
        return handler.next(options);
      },
      onError: (DioException error, ErrorInterceptorHandler handler) async {
        if (error.response?.statusCode == 401) {
          debugPrint('--- DETECTED 401 ERROR ---');
          final refreshToken = await AuthHelper.getRefreshToken();
          final accessToken = await AuthHelper.getAccessToken();
          debugPrint('--- Refresh Token Available: ${refreshToken != null} ---');

          if (refreshToken != null) {
            try {
              debugPrint('--- ATTEMPTING REFRESH ---');
              // Call refresh endpoint
              // We use a separate Dio instance to avoid circular dependency/interceptor issues
              final refreshDio = Dio(BaseOptions(baseUrl: dio.options.baseUrl));
              
              final response = await refreshDio.post('/userv2/session', data: {
                'accessToken': accessToken,
                'refreshToken': refreshToken,
              });
              
              debugPrint('--- REFRESH RESPONSE STATUS: ${response.statusCode} ---');

              if (response.statusCode == 200 || response.statusCode == 201) {
                final newAccessToken = response.data['accessToken'];
                final newRefreshToken = response.data['refreshToken'];
                debugPrint('--- REFRESH SUCCESS ---');

                // Save new tokens
                await AuthHelper.saveTokenAndUser(newAccessToken);
                await AuthHelper.saveRefreshToken(newRefreshToken);

                // Update the failed request with new token
                final options = error.requestOptions;
                options.headers['Authorization'] = 'Bearer $newAccessToken';

                // Retry the original request
                final retryResponse = await dio.fetch(options);
                return handler.resolve(retryResponse);
              } else {
                debugPrint('--- REFRESH FAILED: Status ${response.statusCode} ---');
              }
            } catch (e) {
              debugPrint('--- REFRESH EXCEPTION: $e ---');
              // Refresh failed
              return handler.next(error);
            }
          } else {
             debugPrint('--- NO REFRESH TOKEN FOUND ---');
          }
        }
        return handler.next(error);
      },
    ));
  }
}