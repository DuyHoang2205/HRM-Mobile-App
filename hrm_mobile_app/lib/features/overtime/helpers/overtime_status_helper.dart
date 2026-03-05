import 'package:flutter/material.dart';
import '../models/overtime_request.dart';
import '../models/attendance_record.dart';
import '../models/leave_record.dart';

/// Trạng thái hiển thị của phiếu tăng ca — derive client-side
/// từ fromDate/toDate + dữ liệu chấm công + dữ liệu nghỉ phép.
enum OvertimeDisplayStatus {
  /// fromDate > now
  upcoming,

  /// fromDate <= now <= toDate
  inProgress,

  /// Có đơn nghỉ phép được duyệt cắt qua thời gian tăng ca
  onLeave,

  /// now > toDate + nhân viên có chấm công (checkin != null)
  completed,

  /// now > toDate + không chấm công + không có nghỉ phép
  absent,
}

extension OvertimeDisplayStatusX on OvertimeDisplayStatus {
  String get label => switch (this) {
    OvertimeDisplayStatus.upcoming => 'Sắp tới',
    OvertimeDisplayStatus.inProgress => 'Trong ca',
    OvertimeDisplayStatus.onLeave => 'Nghỉ phép',
    OvertimeDisplayStatus.completed => 'Hoàn thành',
    OvertimeDisplayStatus.absent => 'Vắng mặt',
  };

  String get shortLabel => switch (this) {
    OvertimeDisplayStatus.upcoming => 'SẮP TỚI',
    OvertimeDisplayStatus.inProgress => 'TRONG CA',
    OvertimeDisplayStatus.onLeave => 'NGHỈ PHÉP',
    OvertimeDisplayStatus.completed => 'HOÀN THÀNH',
    OvertimeDisplayStatus.absent => 'VẮNG MẶT',
  };

  Color get color => switch (this) {
    OvertimeDisplayStatus.upcoming => const Color(0xFF2196F3),
    OvertimeDisplayStatus.inProgress => const Color(0xFF00C389),
    OvertimeDisplayStatus.onLeave => const Color(0xFFFF9800),
    OvertimeDisplayStatus.completed => const Color(0xFF4CAF50),
    OvertimeDisplayStatus.absent => const Color(0xFFF44336),
  };

  IconData get icon => switch (this) {
    OvertimeDisplayStatus.upcoming => Icons.schedule,
    OvertimeDisplayStatus.inProgress => Icons.work,
    OvertimeDisplayStatus.onLeave => Icons.beach_access,
    OvertimeDisplayStatus.completed => Icons.check_circle,
    OvertimeDisplayStatus.absent => Icons.cancel,
  };
}

/// Tính toán display status từ: overtime record + attendance + leaves.
OvertimeDisplayStatus computeOvertimeStatus({
  required OvertimeRequest overtime,
  required List<AttendanceRecord> attendance,
  required List<LeaveRecord> leaves,
  DateTime? now,
}) {
  final currentTime = now ?? DateTime.now();

  // 1. Kiểm tra nghỉ phép được duyệt giao với ca tăng ca
  final hasApprovedLeave = leaves.any(
    (leave) =>
        leave.isApproved &&
        (leave.employeeId == 0 || leave.employeeId == overtime.requestBy) &&
        leave.overlaps(overtime.fromDate, overtime.toDate),
  );
  if (hasApprovedLeave) return OvertimeDisplayStatus.onLeave;

  // 2. Chưa tới giờ làm
  if (overtime.fromDate.isAfter(currentTime)) {
    return OvertimeDisplayStatus.upcoming;
  }

  // 3. Đang trong ca
  if (currentTime.isBefore(overtime.toDate) ||
      currentTime.isAtSameMomentAs(overtime.toDate)) {
    return OvertimeDisplayStatus.inProgress;
  }

  // 4. Đã qua ca — kiểm tra chấm công trong ngày tăng ca
  final otDate = overtime.fromDate;
  final hasCheckin = attendance.any((att) {
    if (att.day == null) return false;
    return att.day!.year == otDate.year &&
        att.day!.month == otDate.month &&
        att.day!.day == otDate.day &&
        att.isPresent;
  });

  return hasCheckin
      ? OvertimeDisplayStatus.completed
      : OvertimeDisplayStatus.absent;
}
