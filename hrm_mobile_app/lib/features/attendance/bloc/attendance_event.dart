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

class AttendanceCheckResultArrived extends AttendanceEvent {
  final bool isCheckIn;
  final DateTime timestamp;

  const AttendanceCheckResultArrived({required this.isCheckIn, required this.timestamp});

  @override
  List<Object?> get props => [isCheckIn, timestamp];
}