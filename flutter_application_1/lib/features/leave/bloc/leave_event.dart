import '../models/leave_request.dart';

abstract class LeaveEvent {
  const LeaveEvent();
}

class LeaveStarted extends LeaveEvent {
  const LeaveStarted();
}

class LeaveRefreshed extends LeaveEvent {
  const LeaveRefreshed();
}

class LeaveRequestSubmitted extends LeaveEvent {
  final LeaveRequest request;
  const LeaveRequestSubmitted(this.request);
}
