import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../app/config/app_config.dart';
import '../models/login_response.dart';

class AuthRepository {
  AuthRepository();

  Future<LoginResponse> login({
    required String username,
    required String password,
    required String siteId,
  }) async {
    try {
      final response = await _loginLocal(
        username: username,
        password: password,
        siteId: siteId,
      );

      _debug('[AuthRepository] Login status: ${response.statusCode}');
      _debug('[AuthRepository] Login raw response: ${response.data}');

      if (response.statusCode != 200) {
        _debug('!!! AUTH_REPO: DETECTED NON-200 STATUS: ${response.statusCode} - THROWING !!!');
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Login failed with status ${response.statusCode}',
        );
      }

      var data = response.data;
      if (data is Map<String, dynamic> && data.containsKey('errors')) {
        _debug('!!! AUTH_REPO: DETECTED ERRORS IN BODY - THROWING !!!');
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Unauthorized',
        );
      }

      if (data is List && data.isNotEmpty) {
        data = data.first;
      }
      
      if (data is! Map<String, dynamic>) {
        _debug('[AuthRepository] Invalid response type: ${data.runtimeType}');
        throw const FormatException('Invalid login response format');
      }
      final parsed = LoginResponse.fromJson(data);
      var loginResponse = parsed.copyWith(
        username: parsed.username ?? username,
        siteId: parsed.siteId ?? siteId,
      );

      loginResponse = await _hydrateEmployeeIdentity(
        loginResponse,
        username: username,
        siteId: siteId,
        accessToken: parsed.accessToken,
      );

      final hasIdentity =
          loginResponse.employeeId != null &&
          (loginResponse.siteId ?? '').isNotEmpty;

      if (!hasIdentity) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Missing login identity',
        );
      }
      return loginResponse;
    } on DioException catch (e) {
      _debug(
        '[AuthRepository] Login failed: type=${e.type} status=${e.response?.statusCode} message=${e.message} error=${e.error}',
      );
      if (e.error != null) _debug('[AuthRepository] Underlying error: ${e.error}');
      rethrow;
    } on FormatException {
      rethrow;
    }
  }

  Future<Response<dynamic>> _loginLocal({
    required String username,
    required String password,
    required String siteId,
  }) async {
    const legacyUrl = 'http://erp.vietgoat.com:854/erp/Users/weblogin';
    _debug('[AuthRepository] ATTEMPTING LEGACY LOGIN: $legacyUrl');
    
    final dio = Dio(BaseOptions(
      validateStatus: (status) => status != null && status < 600,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      contentType: 'application/json; charset=utf-8',
    ));

    return dio.post(
      legacyUrl,
      data: {
        'No_': username,
        'Password': password,
        'site': siteId,
      },
      options: Options(
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'HRM-Mobile-App',
        },
      ),
    );
  }

  Future<LoginResponse> _hydrateEmployeeIdentity(
    LoginResponse response, {
    required String username,
    required String siteId,
    String? accessToken,
  }) async {
    if (response.employeeId != null && (response.siteId ?? '').isNotEmpty) {
      return response;
    }

    final fallback = _localFallbackIdentity(username: username, siteId: siteId);
    if (fallback != null) {
      return response.copyWith(
        employeeId: fallback.employeeId,
        siteId: fallback.siteId,
        fullName: response.fullName ?? fallback.fullName,
        staffCode: response.staffCode ?? fallback.staffCode,
        username: response.username ?? username,
      );
    }

    final resolved = await _resolveEmployeeBySite(
      username: username,
      siteId: siteId,
      accessToken: accessToken ?? response.accessToken,
    );

    if (resolved != null) {
      return response.copyWith(
        employeeId: resolved.employeeId,
        siteId: resolved.siteId ?? siteId,
        fullName: response.fullName ?? resolved.fullName,
        staffCode: response.staffCode ?? resolved.staffCode,
        username: response.username ?? username,
      );
    }

    return response.copyWith(
      username: response.username ?? username,
      siteId: response.siteId ?? siteId,
    );
  }

  Future<_ResolvedEmployee?> _resolveEmployeeBySite({
    required String username,
    required String siteId,
    String? accessToken,
  }) async {
    final apiBase = AppConfig.apiBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final dio = Dio(
      BaseOptions(
        baseUrl: '$apiBase/',
        validateStatus: (status) => status != null && status < 600,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    try {
      final response = await dio.get(
        '/employee/list-employee',
        queryParameters: {'site': siteId},
        options: Options(
          headers: {
            if ((accessToken ?? '').isNotEmpty)
              'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode != 200 || response.data is! List) {
        return null;
      }

      for (final item in response.data as List) {
        if (item is! Map<String, dynamic>) continue;

        final accountId =
            item['accountID']?.toString().trim().toLowerCase() ??
            item['AccountID']?.toString().trim().toLowerCase();
        final userName =
            item['userName']?.toString().trim().toLowerCase() ??
            item['UserName']?.toString().trim().toLowerCase();
        final code =
            item['code']?.toString().trim().toLowerCase() ??
            item['Code']?.toString().trim().toLowerCase();
        final lookup = username.trim().toLowerCase();

        if (accountId == lookup || userName == lookup || code == lookup) {
          final idRaw = item['employeeId'] ?? item['id'] ?? item['ID'];
          final employeeId = int.tryParse(idRaw?.toString() ?? '');
          if (employeeId == null || employeeId <= 0) continue;

          return _ResolvedEmployee(
            employeeId: employeeId,
            siteId:
                item['siteID']?.toString() ??
                item['siteId']?.toString() ??
                siteId,
            fullName:
                item['fullName']?.toString() ??
                item['FullName']?.toString(),
            staffCode: item['code']?.toString() ?? item['Code']?.toString(),
          );
        }
      }
    } catch (e) {
      _debug('[AuthRepository] Resolve employee failed: $e');
    }

    return null;
  }

  _ResolvedEmployee? _localFallbackIdentity({
    required String username,
    required String siteId,
  }) {
    final key = '${siteId.trim().toUpperCase()}::${username.trim().toLowerCase()}';
    switch (key) {
      case 'KIA::admin':
        return const _ResolvedEmployee(
          employeeId: 8847,
          siteId: 'KIA',
          fullName: 'CAO VĂN ĐỒNG',
          staffCode: '200190',
        );
      case 'KIA::baoduy':
        return const _ResolvedEmployee(
          employeeId: 11394,
          siteId: 'KIA',
          fullName: 'BẢO DUY MOBILE',
          staffCode: 'BAODUYKIA',
        );
    }
    return null;
  }

  void _debug(String message) {
    if (!kDebugMode) return;
    debugPrint(message);
  }
}

class _ResolvedEmployee {
  final int employeeId;
  final String? siteId;
  final String? fullName;
  final String? staffCode;

  const _ResolvedEmployee({
    required this.employeeId,
    this.siteId,
    this.fullName,
    this.staffCode,
  });
}
