import 'package:equatable/equatable.dart';
import '../../../core/utils/attendance_day_policy.dart';
import '../models/attendance_log.dart';
import '../models/daily_summary.dart';

class AttendanceState extends Equatable {
  final List<AttendanceLog> logs;
  final bool isLoading;
  final String? error;
  final DateTime filterDate; // This acts as the startDate
  final DateTime? endDate;
  final Map<String, AttendancePolicyConfig> dayPolicies;
  final Map<String, DailySummary> dailySummaries;
  final bool isSubmittingChange;
  final String? changeSuccessMessage;

  const AttendanceState({
    required this.logs,
    this.isLoading = false,
    this.error,
    required this.filterDate,
    this.endDate,
    this.dayPolicies = const {},
    this.dailySummaries = const {},
    this.isSubmittingChange = false,
    this.changeSuccessMessage,
  });

  factory AttendanceState.initial() {
    final now = DateTime.now();
    return AttendanceState(
      logs: const [],
      filterDate: DateTime(now.year, now.month, 1), // Start of month
      endDate: now, // Today
      dayPolicies: const {},
      dailySummaries: const {},
    );
  }

  // Helper to determine if we are currently checked in based on newest log
  bool get isCheckedIn =>
      logs.isNotEmpty && logs.first.action == AttendanceAction.checkIn;

  AttendanceState copyWith({
    List<AttendanceLog>? logs,
    bool? isLoading,
    String? error,
    DateTime? filterDate,
    DateTime? endDate,
    Map<String, AttendancePolicyConfig>? dayPolicies,
    Map<String, DailySummary>? dailySummaries,
    bool? isSubmittingChange,
    String? changeSuccessMessage,
  }) {
    return AttendanceState(
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
      error: error != null ? (error.isEmpty ? null : error) : this.error,
      filterDate: filterDate ?? this.filterDate,
      endDate: endDate ?? this.endDate,
      dayPolicies: dayPolicies ?? this.dayPolicies,
      dailySummaries: dailySummaries ?? this.dailySummaries,
      isSubmittingChange: isSubmittingChange ?? this.isSubmittingChange,
      changeSuccessMessage: changeSuccessMessage != null ? (changeSuccessMessage.isEmpty ? null : changeSuccessMessage) : this.changeSuccessMessage,
    );
  }

  @override
  List<Object?> get props => [
    logs,
    isLoading,
    error,
    filterDate,
    endDate,
    dayPolicies,
    dailySummaries,
    isSubmittingChange,
    changeSuccessMessage,
  ];
}
