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
