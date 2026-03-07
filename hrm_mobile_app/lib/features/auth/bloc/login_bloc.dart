import 'package:flutter_bloc/flutter_bloc.dart';
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
        siteId: 'REEME',
      );

      // Save token and decode employeeId/site from JWT for attendance APIs
      await AuthHelper.saveTokenAndUser(loginResponse.accessToken);
      await AuthHelper.saveRefreshToken(loginResponse.refreshToken);
      if (loginResponse.staffCode != null &&
          loginResponse.staffCode!.isNotEmpty) {
        await AuthHelper.saveStaffCode(loginResponse.staffCode!);
      }

      emit(const LoginState(status: LoginStatus.success));
    } on DioException catch (e) {
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
