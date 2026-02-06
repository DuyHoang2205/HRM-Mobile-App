import '../models/leave_request.dart';

class LeaveState {
  final bool isLoading;
  final List<LeaveRequest> requests;
  final String? error;
  final bool isSubmitting;
  final String? submitSuccess;

  const LeaveState({
    this.isLoading = false,
    this.requests = const [],
    this.error,
    this.isSubmitting = false,
    this.submitSuccess,
  });

  LeaveState copyWith({
    bool? isLoading,
    List<LeaveRequest>? requests,
    String? error,
    bool? isSubmitting,
    String? submitSuccess,
  }) {
    return LeaveState(
      isLoading: isLoading ?? this.isLoading,
      requests: requests ?? this.requests,
      error: error,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitSuccess: submitSuccess,
    );
  }
}
