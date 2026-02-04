import 'package:equatable/equatable.dart';
import '../models/attendance_log.dart';

class AttendanceState extends Equatable {
  final List<AttendanceLog> logs;
  final bool isLoading;
  final String? error;

  const AttendanceState({
    required this.logs,
    this.isLoading = false,
    this.error,
  });

  factory AttendanceState.initial() => const AttendanceState(logs: []);

  AttendanceState copyWith({
    List<AttendanceLog>? logs,
    bool? isLoading,
    String? error,
  }) {
    return AttendanceState(
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [logs, isLoading, error];
}
