import 'package:equatable/equatable.dart';

abstract class CheckInEvent extends Equatable {
  const CheckInEvent();

  @override
  List<Object?> get props => [];
}

class CheckInStarted extends CheckInEvent {
  const CheckInStarted();
}

class RefreshLocationPressed extends CheckInEvent {
  const RefreshLocationPressed();
}

class PrivacyPressed extends CheckInEvent {
  const PrivacyPressed();
}

class ShiftSelected extends CheckInEvent {
  final String shiftId;
  const ShiftSelected(this.shiftId);

  @override
  List<Object?> get props => [shiftId];
}

class ConfirmPressed extends CheckInEvent {
  const ConfirmPressed();
}
