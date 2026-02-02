enum AttendanceAction { checkIn, checkOut }

class AttendanceLog {
  final DateTime timestamp;
  final AttendanceAction action;
  final String userName;
  final String subtitle;

  const AttendanceLog({
    required this.timestamp,
    required this.action,
    required this.userName,
    required this.subtitle,
  });
}
