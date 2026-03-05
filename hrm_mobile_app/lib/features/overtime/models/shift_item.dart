/// Model cho Ca làm việc (Shift) — từ bảng Shift trên DB.
/// Dùng làm Dropdown khi đăng ký Tăng ca.
class ShiftItem {
  final int id;
  final String title;
  final String? code;

  /// Tổng số giờ làm (workTime từ DB, dạng decimal)
  final double workTime;

  const ShiftItem({
    required this.id,
    required this.title,
    this.code,
    this.workTime = 0,
  });

  factory ShiftItem.fromJson(Map<String, dynamic> json) {
    return ShiftItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? 'Ca #${json['id']}',
      code: json['code']?.toString(),
      workTime: (json['workTime'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Nhãn hiển thị trong Dropdown: "TĂNG CA THƯỜNG (5.5 giờ)"
  String get displayLabel {
    if (workTime <= 0) return title;
    final hrs = workTime % 1 == 0
        ? workTime.toInt().toString()
        : workTime.toString();
    return '$title  ($hrs giờ)';
  }

  @override
  String toString() => 'ShiftItem(id: $id, title: $title, workTime: $workTime)';
}
