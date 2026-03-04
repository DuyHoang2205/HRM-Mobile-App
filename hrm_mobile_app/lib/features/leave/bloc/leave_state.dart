import '../models/leave_request.dart';
import '../models/permission_type_item.dart';

class LeaveState {
  final bool isLoading;
  final List<LeaveRequest> requests;
  final List<PermissionTypeItem> permissionTypes;
  final String? error;
  final bool isSubmitting;
  final String? submitSuccess;
  final String? errorMessage; // Lỗi khi submit

  const LeaveState({
    this.isLoading = false,
    this.requests = const [],
    this.permissionTypes = const [],
    this.error,
    this.isSubmitting = false,
    this.submitSuccess,
    this.errorMessage,
  });

  LeaveState copyWith({
    bool? isLoading,
    List<LeaveRequest>? requests,
    List<PermissionTypeItem>? permissionTypes,
    String? error,
    bool? isSubmitting,
    String? submitSuccess,
    String? errorMessage,
  }) {
    return LeaveState(
      isLoading: isLoading ?? this.isLoading,
      requests: requests ?? this.requests,
      permissionTypes: permissionTypes ?? this.permissionTypes,
      error: error,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitSuccess: submitSuccess,
      errorMessage: errorMessage,
    );
  }
}
