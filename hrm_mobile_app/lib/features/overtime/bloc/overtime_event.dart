abstract class OvertimeEvent {
  const OvertimeEvent();
}

class LoadOvertimeList extends OvertimeEvent {
  const LoadOvertimeList();
}

class SubmitOvertimeRequest extends OvertimeEvent {
  final DateTime date;
  final String startTime;
  final String endTime;
  final String reason;
  final String description;
  final bool isNextDay;
  final int breakMinutes;
  final String? reeproDispatch;
  final String? reeproProject;

  const SubmitOvertimeRequest({
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.reason,
    required this.description,
    required this.isNextDay,
    required this.breakMinutes,
    this.reeproDispatch,
    this.reeproProject,
  });
}
