/// Record chấm công từ EXEC AttendanceFilterByEmployee
class AttendanceRecord {
  final String? code; // Employee code
  final String? fullName;
  final DateTime? day; // Ngày chấm
  final String? checkin; // Giờ checkin (null = không chấm)
  final String? checkout; // Giờ checkout
  final bool noScan; // true = không quẹt thẻ
  final bool isAbsent; // true = vắng mặt

  const AttendanceRecord({
    this.code,
    this.fullName,
    this.day,
    this.checkin,
    this.checkout,
    this.noScan = false,
    this.isAbsent = false,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      code: json['code']?.toString(),
      fullName: json['fullName']?.toString(),
      day: json['day'] != null
          ? DateTime.tryParse(json['day'].toString())
          : null,
      checkin: json['checkin']?.toString(),
      checkout: json['checkout']?.toString(),
      noScan: _parseBool(json['noScan']),
      isAbsent: _parseBool(json['isAbsent']),
    );
  }

  /// Nhân viên có mặt = có checkin và không phải vắng mặt
  bool get isPresent => checkin != null && checkin!.isNotEmpty && !isAbsent;

  static bool _parseBool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is int) return v != 0;
    return v.toString().toLowerCase() == 'true' || v.toString() == '1';
  }
}
