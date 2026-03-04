import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/auth/auth_helper.dart';
import '../../main.dart';
import '../../features/auth/view/login_screen.dart';

class DioClient {
  late final Dio dio;

  DioClient() {
    // ─── BACKEND URL CONFIG ───────────────────────────────────────────
    // Dùng URL production mặc định
    const prodUrl = 'http://vpn.dptsolution.net:853/hrm/api/';

    // Khi cần test local, bạn chỉ cần comment dòng `baseUrl: prodUrl` ở dưới
    // và uncomment dòng `baseUrl: localUrl`
    // ignore: unused_local_variable
    const localUrl = 'http://localhost:3004/api/';

    dio = Dio(
      BaseOptions(
        baseUrl: prodUrl, // ← Thay bằng `localUrl` khi cần test backend local

        validateStatus: (status) {
          if (status == null) return false;
          if (status == 401) return false; // Trigger onError for token refresh
          return status < 500;
        },
        contentType: 'application/json; charset=utf-8',
      ),
    );

    dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await AuthHelper.getAccessToken();

          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, ErrorInterceptorHandler handler) async {
          if (error.response?.statusCode == 401) {
            // Skip token refresh for login endpoint
            if (error.requestOptions.path.toLowerCase().contains('login')) {
              return handler.next(error);
            }

            debugPrint('--- DETECTED 401 ERROR ---');
            final refreshToken = await AuthHelper.getRefreshToken();
            final accessToken = await AuthHelper.getAccessToken();
            debugPrint(
              '--- Refresh Token Available: ${refreshToken != null} ---',
            );

            if (refreshToken != null) {
              try {
                debugPrint('--- ATTEMPTING REFRESH ---');
                // Call refresh endpoint
                // We use a separate Dio instance to avoid circular dependency/interceptor issues
                final refreshDio = Dio(
                  BaseOptions(baseUrl: dio.options.baseUrl),
                );

                final response = await refreshDio.post(
                  '/userv2/session',
                  data: {
                    'accessToken': accessToken,
                    'refreshToken': refreshToken,
                  },
                );

                debugPrint(
                  '--- REFRESH RESPONSE STATUS: ${response.statusCode} ---',
                );

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
                  debugPrint(
                    '--- REFRESH FAILED: Status ${response.statusCode} ---',
                  );
                  await _logoutAndRedirect();
                }
              } catch (e) {
                debugPrint('--- REFRESH EXCEPTION: $e ---');
                // Refresh failed
                await _logoutAndRedirect();
                return handler.next(error);
              }
            } else {
              debugPrint('--- NO REFRESH TOKEN FOUND ---');
              await _logoutAndRedirect();
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<void> _logoutAndRedirect() async {
    await AuthHelper.clear();
    final context = navigatorKey.currentContext;
    if (context != null) {
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }
}
