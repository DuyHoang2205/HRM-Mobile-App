import 'package:equatable/equatable.dart';

enum LoginStatus { initial, loading, success, failure }

class LoginState extends Equatable {
  final LoginStatus status;
  final String? error;

  const LoginState({
    this.status = LoginStatus.initial,
    this.error,
  });

  @override
  List<Object?> get props => [status, error];
}