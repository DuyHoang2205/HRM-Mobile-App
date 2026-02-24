import '../models/overtime_request.dart';

abstract class OvertimeEvent {
  const OvertimeEvent();
}

class OvertimeStarted extends OvertimeEvent {
  const OvertimeStarted();
}

class OvertimeRefreshed extends OvertimeEvent {
  const OvertimeRefreshed();
}

class OvertimeRequestSubmitted extends OvertimeEvent {
  final OvertimeRequest request;
  const OvertimeRequestSubmitted(this.request);
}
