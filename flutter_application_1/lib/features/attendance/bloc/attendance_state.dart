import 'package:equatable/equatable.dart';
import '../models/attendance_log.dart';

class AttendanceState extends Equatable {
  final List<AttendanceLog> logs;

  const AttendanceState({required this.logs});

  factory AttendanceState.initial() => const AttendanceState(logs: []);

  AttendanceState copyWith({List<AttendanceLog>? logs}) {
    return AttendanceState(logs: logs ?? this.logs);
  }

  @override
  List<Object?> get props => [logs];
}
