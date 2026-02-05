import 'package:equatable/equatable.dart';
import '../models/attendance_log.dart';

class AttendanceState extends Equatable {
  final List<AttendanceLog> logs;
  final bool isLoading;
  final String? error;
  final bool isCheckedIn; // Derived from logs
  final DateTime filterDate;

  const AttendanceState({
    required this.logs,
    this.isLoading = false,
    this.error,
    this.isCheckedIn = false,
    required this.filterDate,
  });

  factory AttendanceState.initial() => AttendanceState(
    logs: const [], 
    filterDate: DateTime.now(),
  );

  AttendanceState copyWith({
    List<AttendanceLog>? logs,
    bool? isLoading,
    String? error,
    bool? isCheckedIn,
    DateTime? filterDate,
  }) {
    return AttendanceState(
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isCheckedIn: isCheckedIn ?? this.isCheckedIn,
      filterDate: filterDate ?? this.filterDate,
    );
  }

  @override
  List<Object?> get props => [logs, isLoading, error, isCheckedIn, filterDate];
}
