import 'package:equatable/equatable.dart';

abstract class AttendanceEvent extends Equatable {
  const AttendanceEvent();
  @override
  List<Object?> get props => [];
}

class AttendanceStarted extends AttendanceEvent {
  const AttendanceStarted();
}

class AttendanceRefreshed extends AttendanceEvent {
  const AttendanceRefreshed();
}

class AttendanceFilterChanged extends AttendanceEvent {
  final DateTime start;
  final DateTime end;

  const AttendanceFilterChanged({required this.start, required this.end});

  @override
  List<Object?> get props => [start, end];
}

class AttendanceTimesheetDateChanged extends AttendanceEvent {
  final DateTime start;
  final DateTime end;

  const AttendanceTimesheetDateChanged({
    required this.start,
    required this.end,
  });

  @override
  List<Object?> get props => [start, end];
}

class AttendanceCheckResultArrived extends AttendanceEvent {
  final bool isCheckIn;
  final DateTime timestamp;

  const AttendanceCheckResultArrived({
    required this.isCheckIn,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [isCheckIn, timestamp];
}

class AttendanceChangeSubmitted extends AttendanceEvent {
  final String date; // YYYY-MM-DD
  final String time; // HH:MM:SS
  final int shiftID;
  final String reason;
  final String note;
  final List<String> attachmentPaths;

  const AttendanceChangeSubmitted({
    required this.date,
    required this.time,
    required this.shiftID,
    required this.reason,
    this.note = '',
    this.attachmentPaths = const [],
  });

  @override
  List<Object?> get props => [
    date,
    time,
    shiftID,
    reason,
    note,
    attachmentPaths,
  ];
}
