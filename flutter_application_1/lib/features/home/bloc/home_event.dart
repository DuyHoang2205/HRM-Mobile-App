import 'package:equatable/equatable.dart';
import '../../attendance/models/attendance_log.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class HomeStarted extends HomeEvent {
  const HomeStarted();
}

// THIS WAS MISSING:
class AttendanceLogsRequested extends HomeEvent {
  const AttendanceLogsRequested();
}

class AttendanceLogsLoaded extends HomeEvent {
  final List<AttendanceLog> logs;
  const AttendanceLogsLoaded(this.logs);

  @override
  List<Object?> get props => [logs];
}

class CheckResultArrived extends HomeEvent {
  final DateTime timestamp;
  final bool isCheckIn;
  const CheckResultArrived({required this.timestamp, required this.isCheckIn});

  @override
  List<Object?> get props => [timestamp, isCheckIn];
}

class NotificationTapped extends HomeEvent {}
class CheckInTapped extends HomeEvent {}