import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class HomeStarted extends HomeEvent {
  const HomeStarted();
}

class NotificationTapped extends HomeEvent {
  const NotificationTapped();
}

class CheckInTapped extends HomeEvent {
  const CheckInTapped();
}

class CheckResultArrived extends HomeEvent {
  final DateTime timestamp;
  final bool isCheckIn; // true = check-in, false = check-out

  const CheckResultArrived({
    required this.timestamp,
    required this.isCheckIn,
  });

  @override
  List<Object?> get props => [timestamp, isCheckIn];
}
