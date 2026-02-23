import 'package:equatable/equatable.dart';
import '../models/attendance_log.dart';

class AttendanceState extends Equatable {
  final List<AttendanceLog> logs;
  final bool isLoading;
  final String? error;
  final DateTime filterDate; // This acts as the startDate
  final DateTime? endDate;

  const AttendanceState({
    required this.logs,
    this.isLoading = false,
    this.error,
    required this.filterDate,
    this.endDate,
  });

  factory AttendanceState.initial() {
    final now = DateTime.now();
    return AttendanceState(
      logs: const [],
      filterDate: DateTime(now.year, now.month, 1), // Start of month
      endDate: now, // Today
    );
  }

  // Helper to determine if we are currently checked in based on newest log
  bool get isCheckedIn => logs.isNotEmpty && logs.first.action == AttendanceAction.checkIn;

  AttendanceState copyWith({
    List<AttendanceLog>? logs,
    bool? isLoading,
    String? error,
    DateTime? filterDate,
    DateTime? endDate,
  }) {
    return AttendanceState(
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      filterDate: filterDate ?? this.filterDate,
      endDate: endDate ?? this.endDate,
    );
  }

  @override
  List<Object?> get props => [logs, isLoading, error, filterDate, endDate];
}