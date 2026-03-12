class AttendanceChangeRequest {
  final int employeeID;
  final DateTime authDate;
  final String authTime; // Ví dụ: '2026-02-10T17:30:00'
  final String createdBy;
  final String siteID;

  AttendanceChangeRequest({
    required this.employeeID,
    required this.authDate,
    required this.authTime,
    required this.createdBy,
    required this.siteID,
  });

  Map<String, dynamic> toJson() {
    return {
      'employeeID': employeeID,
      'authDate': authDate.toIso8601String(),
      'authTime': authTime,
      'createdBy': createdBy,
      'siteID': siteID,
    };
  }
}
