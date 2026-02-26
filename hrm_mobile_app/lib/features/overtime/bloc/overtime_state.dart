import '../models/overtime_model.dart';

enum OvertimeStatus {
  initial,
  loading,
  success,
  failure,
  submitting,
  submitSuccess,
  submitFailure,
}

class OvertimeState {
  final OvertimeStatus status;
  final List<OvertimeModel> requests;
  final String? errorMessage;

  const OvertimeState({
    this.status = OvertimeStatus.initial,
    this.requests = const [],
    this.errorMessage,
  });

  OvertimeState copyWith({
    OvertimeStatus? status,
    List<OvertimeModel>? requests,
    String? errorMessage,
  }) {
    return OvertimeState(
      status: status ?? this.status,
      requests: requests ?? this.requests,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
