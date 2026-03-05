import 'package:equatable/equatable.dart';
import '../models/overtime_request.dart';
import '../models/shift_item.dart';
import '../models/employee_item.dart';
import '../models/attendance_record.dart';
import '../models/leave_record.dart';

class OvertimeState extends Equatable {
  final bool isLoading;
  final bool isSubmitting;
  final List<OvertimeRequest> requests;
  final List<ShiftItem> shifts;

  /// Danh sách nhân viên — chỉ load khi isHR = true
  final List<EmployeeItem> employees;

  /// Dữ liệu chấm công trong kỳ hiện tại (dùng derive status)
  final List<AttendanceRecord> attendance;

  /// Đơn nghỉ trong năm của NV (dùng derive status)
  final List<LeaveRecord> leaves;

  /// true = user có quyền frmOvertime/Add (HR/Admin)
  final bool isHR;

  final String? error;
  final String? errorMessage;
  final String? submitSuccess;

  const OvertimeState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.requests = const [],
    this.shifts = const [],
    this.employees = const [],
    this.attendance = const [],
    this.leaves = const [],
    this.isHR = false,
    this.error,
    this.errorMessage,
    this.submitSuccess,
  });

  OvertimeState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    List<OvertimeRequest>? requests,
    List<ShiftItem>? shifts,
    List<EmployeeItem>? employees,
    List<AttendanceRecord>? attendance,
    List<LeaveRecord>? leaves,
    bool? isHR,
    String? error,
    String? errorMessage,
    String? submitSuccess,
  }) {
    return OvertimeState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      requests: requests ?? this.requests,
      shifts: shifts ?? this.shifts,
      employees: employees ?? this.employees,
      attendance: attendance ?? this.attendance,
      leaves: leaves ?? this.leaves,
      isHR: isHR ?? this.isHR,
      error: error,
      errorMessage: errorMessage,
      submitSuccess: submitSuccess,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isSubmitting,
    requests,
    shifts,
    employees,
    attendance,
    leaves,
    isHR,
    error,
    errorMessage,
    submitSuccess,
  ];
}
