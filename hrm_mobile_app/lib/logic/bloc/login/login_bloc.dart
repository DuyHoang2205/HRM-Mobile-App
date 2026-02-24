import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../../core/auth/auth_helper.dart';
import '../../../core/network/dio_client.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  // Use the same client setup as your HomeBloc
  final DioClient _dioClient = DioClient();

  LoginBloc() : super(const LoginState()) {
    on<LoginSubmitted>(_onLoginSubmitted);
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    emit(const LoginState(status: LoginStatus.loading));
    try {
      // Hits @Post('login') in NestJS Userv2Controller
      final response = await _dioClient.dio.post('/UserV2/login', data: {
        'username': event.username,
        'password': event.password,
        'siteId': 'REEME', // Keeping the siteId as REEME like before
      });

      // Ensure response data is not null before accessing it
      if (response.data == null) {
        throw Exception('Login failed');
      }

      // Safely handle if data is somehow not a map
      final data = response.data is Map ? response.data : {};

      // NestJS returns the token in this field, fallback securely to avoid string cast crashes
      final String token = data['accessToken']?.toString() ?? '';
      final String refreshToken = data['refreshToken']?.toString() ?? '';

      if (token.isEmpty) {
        throw Exception('Login failed');
      }

      // Extract staffCode if available
      final employeeInfo = data['employeeInfo'];
      final staffCode = employeeInfo != null ? employeeInfo['staffCode']?.toString() : null;

      // Save token and decode employeeId/site from JWT for attendance APIs
      await AuthHelper.saveTokenAndUser(token);
      await AuthHelper.saveRefreshToken(refreshToken);
      if (staffCode != null) {
        await AuthHelper.saveStaffCode(staffCode);
      }

      emit(const LoginState(status: LoginStatus.success));
    } on DioException catch (e) {
      if (e.response != null) {
        emit(LoginState(status: LoginStatus.failure, error: 'Server says: ${e.response?.data}'));
      } else {
        emit(LoginState(status: LoginStatus.failure, error: 'Network error: ${e.message}'));
      }
    } catch (e) {
      // Show raw Exception string temporarily for debugging
      emit(LoginState(status: LoginStatus.failure, error: e.toString()));
    }
  }
}