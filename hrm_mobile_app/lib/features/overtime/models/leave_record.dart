/// Record đơn nghỉ phép từ EXEC GetOnLeaveFileByEmployee
class LeaveRecord {
  final int id;
  final int employeeId;

  /// 0=Chờ duyệt, 2=Đã duyệt (HR), 3=Chờ duyệt cấp 2, 4=Từ chối
  final int status;
  final DateTime fromDate;
  final DateTime toDate;

  const LeaveRecord({
    required this.id,
    required this.employeeId,
    required this.status,
    required this.fromDate,
    required this.toDate,
  });

  factory LeaveRecord.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value, {int fallback = 0}) {
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? fallback;
    }

    DateTime parseDate(dynamic value) {
      return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
    }

    return LeaveRecord(
      id: toInt(json['id'] ?? json['ID']),
      employeeId: toInt(
        json['employeeId'] ?? json['employeeID'] ?? json['EmployeeID'],
      ),
      status: toInt(json['status'] ?? json['Status']),
      fromDate: parseDate(json['fromDate'] ?? json['FromDate']),
      toDate: parseDate(json['toDate'] ?? json['ToDate']),
    );
  }

  /// Đơn nghỉ đã được HR duyệt (hoặc cấp quản lý). Có thể là 2 hoặc 3 tùy flow.
  bool get isApproved => status == 2 || status == 3;

  /// Kiểm tra đơn nghỉ có giao với khoảng [from, to] không
  bool overlaps(DateTime from, DateTime to) {
    return !fromDate.isAfter(to) && !toDate.isBefore(from);
  }
}
