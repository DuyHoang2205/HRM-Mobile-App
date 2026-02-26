class OvertimeModel {
  final String id;
  final DateTime date;
  final String startTime;
  final String endTime;
  final double totalHours;
  final String reason;
  final String description;
  final int breakMinutes;
  final String? reeproDispatch;
  final String? reeproProject;
  final String approverName;
  final String status; // e.g. 'PENDING', 'APPROVED', 'REJECTED'
  final bool isNextDay;

  OvertimeModel({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.totalHours,
    required this.reason,
    required this.description,
    required this.breakMinutes,
    this.reeproDispatch,
    this.reeproProject,
    required this.approverName,
    required this.status,
    this.isNextDay = false,
  });
}
