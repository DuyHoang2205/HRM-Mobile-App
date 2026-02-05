import 'package:flutter_bloc/flutter_bloc.dart';
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
      });

      // NestJS returns the token in this field
      final String token = response.data['accessToken'];

      // Save token and decode employeeId/site from JWT for attendance APIs
      await AuthHelper.saveTokenAndUser(token);

      emit(const LoginState(status: LoginStatus.success));
    } catch (e) {
      emit(LoginState(status: LoginStatus.failure, error: e.toString()));
    }
  }
}