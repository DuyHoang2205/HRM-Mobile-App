import '../models/overtime_request.dart';

class OvertimeState {
  final bool isLoading;
  final List<OvertimeRequest> requests;
  final String? error;
  final bool isSubmitting;
  final String? submitSuccess;

  const OvertimeState({
    this.isLoading = false,
    this.requests = const [],
    this.error,
    this.isSubmitting = false,
    this.submitSuccess,
  });

  OvertimeState copyWith({
    bool? isLoading,
    List<OvertimeRequest>? requests,
    String? error,
    bool? isSubmitting,
    String? submitSuccess,
  }) {
    return OvertimeState(
      isLoading: isLoading ?? this.isLoading,
      requests: requests ?? this.requests,
      error: error, // Clear error if not provided? Or strictly null? Usually null overrides.
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitSuccess: submitSuccess,
    );
  }
}
