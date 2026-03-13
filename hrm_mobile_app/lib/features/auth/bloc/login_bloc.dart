import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../data/auth_repository.dart';
import '../../../core/auth/auth_helper.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc({AuthRepository? authRepository})
    : _authRepository = authRepository ?? AuthRepository(),
      super(const LoginState()) {
    on<LoginSubmitted>(_onLoginSubmitted);
  }

  final AuthRepository _authRepository;

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    emit(const LoginState(status: LoginStatus.loading));
    try {
      final loginResponse = await _authRepository.login(
        username: event.username,
        password: event.password,
        siteId: 'KIA', // Default site for the app
      );

      debugPrint('LOGIN_BLOC: received login response');

      // Ưu tiên JWT nếu backend trả về. Nếu không có token, lưu identity từ payload legacy.
      if (loginResponse.accessToken.isNotEmpty) {
        await AuthHelper.saveTokenAndUser(loginResponse.accessToken);
      }
      if (loginResponse.refreshToken.isNotEmpty) {
        await AuthHelper.saveRefreshToken(loginResponse.refreshToken);
      }
      if (loginResponse.staffCode != null &&
          loginResponse.staffCode!.isNotEmpty) {
        await AuthHelper.saveStaffCode(loginResponse.staffCode!);
      }
      if (loginResponse.employeeId != null) {
        await AuthHelper.saveEmployeeId(loginResponse.employeeId!);
      }
      if (loginResponse.siteId != null && loginResponse.siteId!.isNotEmpty) {
        await AuthHelper.saveSiteId(loginResponse.siteId!);
      } else {
        // If server returns no site (common for Admin in this DB), fallback to KIA
        await AuthHelper.saveSiteId('KIA');
      }
      if (loginResponse.fullName != null &&
          loginResponse.fullName!.isNotEmpty) {
        await AuthHelper.saveFullName(loginResponse.fullName!);
      }
      if (loginResponse.username != null &&
          loginResponse.username!.isNotEmpty) {
        await AuthHelper.saveUserName(loginResponse.username!);
      }

      emit(const LoginState(status: LoginStatus.success));
    } on DioException catch (e) {
      debugPrint(
        'LOGIN_BLOC: DioException ${e.message} (status: ${e.response?.statusCode})',
      );
      final message = _extractErrorMessage(e);
      emit(LoginState(status: LoginStatus.failure, error: message));
    } catch (e) {
      emit(
        const LoginState(
          status: LoginStatus.failure,
          error: 'Đăng nhập thất bại. Vui lòng thử lại.',
        ),
      );
    }
  }

  String _extractErrorMessage(DioException exception) {
    final data = exception.response?.data;
    if (data is Map<String, dynamic>) {
      final errors = data['errors'];
      if (errors is List && errors.isNotEmpty) {
        final first = errors.first;
        if (first is Map<String, dynamic>) {
          final code = first['code']?.toString();
          if (code == '3200') {
            return 'Đăng nhập thất bại. Vui lòng kiểm tra tài khoản, mật khẩu hoặc site.';
          }
        }
      }
      final message = data['message'] ?? data['error'] ?? data['msg'];
      if (message != null) return message.toString();
    }
    if (exception.type == DioExceptionType.connectionError ||
        exception.type == DioExceptionType.connectionTimeout) {
      return 'Không thể kết nối máy chủ. Vui lòng kiểm tra mạng.';
    }
    return 'Đăng nhập thất bại. Vui lòng kiểm tra tài khoản hoặc mật khẩu.';
  }
}
