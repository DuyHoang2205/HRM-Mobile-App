enum AttendanceAction { checkIn, checkOut } // Add this line

class AttendanceLog {
  final int id;
  final String userName;
  final String subtitle;
  final DateTime timestamp;
  final AttendanceAction action;

  AttendanceLog({
    required this.id,
    required this.userName,
    required this.subtitle,
    required this.timestamp,
    required this.action,
  });

  factory AttendanceLog.fromJson(Map<String, dynamic> json) {
    final id = json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0;
    final authDate = json['authDate'] ?? json['AuthDate'];
    final dateStr = authDate?.toString();
    final timestamp = dateStr != null && dateStr.isNotEmpty
        ? (DateTime.tryParse(dateStr) ?? DateTime.now())
        : DateTime.now();
    final code = json['attendCode'] ?? json['AttendCode'] ?? '';
    return AttendanceLog(
      id: id,
      userName: code.toString().trim().isEmpty ? 'Chấm công' : "Nhân viên $code",
      subtitle: "Văn phòng - Mobile App",
      timestamp: timestamp,
      action: (id % 2 != 0) ? AttendanceAction.checkIn : AttendanceAction.checkOut,
    );
  }
}