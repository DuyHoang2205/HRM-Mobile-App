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
  final DateTime date;
  const AttendanceFilterChanged(this.date);

  @override
  List<Object?> get props => [date];
}

class AttendanceCheckResultArrived extends AttendanceEvent {
  final bool isCheckIn;
  final DateTime timestamp; // Optional, if we want to add a temporary log
  const AttendanceCheckResultArrived({required this.isCheckIn, required this.timestamp});

  @override
  List<Object?> get props => [isCheckIn, timestamp];
}
