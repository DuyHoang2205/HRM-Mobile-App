/// Model tương ứng với bảng SQL `DecisionOvertime`.
/// Chỉ chứa các trường CÓ THẬT trong Database entity.
class OvertimeRequest {
  final int? id;
  final String code;
  final int status;
  final DateTime fromDate;
  final DateTime toDate;

  /// EmployeeID (FK Employee.ID) — người đăng ký tăng ca
  final int requestBy;

  /// ID Lý do tăng ca (có thể là 0 nếu chưa có danh mục)
  final int reason;

  /// Ghi chú / Diễn giải
  final String note;

  /// ID Ca làm việc (FK Shift.ID)
  final int shiftID;

  /// Số giờ tăng ca
  final double qty;

  final String ignore;
  final String createBy;
  final String updateBy;
  final DateTime? createDate;

  /// Phải là 'OTDocType' để SP xử lý đúng
  final String docType;
  final String siteID;

  const OvertimeRequest({
    this.id,
    this.code = '',
    required this.status,
    required this.fromDate,
    required this.toDate,
    required this.requestBy,
    this.reason = 0,
    required this.note,
    required this.shiftID,
    required this.qty,
    this.ignore = '',
    required this.createBy,
    required this.updateBy,
    this.createDate,
    this.docType = 'OTDocType',
    required this.siteID,
  });

  factory OvertimeRequest.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value, {int fallback = 0}) {
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? fallback;
    }

    double toDouble(dynamic value, {double fallback = 0}) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? fallback;
    }

    return OvertimeRequest(
      id: toInt(json['id'] ?? json['ID'], fallback: 0) == 0
          ? null
          : toInt(json['id'] ?? json['ID']),
      code: (json['code'] ?? json['Code'])?.toString() ?? '',
      status: toInt(json['status'] ?? json['Status']),
      fromDate: _parseTime(json['fromDate'] ?? json['FromDate']),
      toDate: _parseTime(json['toDate'] ?? json['ToDate']),
      requestBy: toInt(json['requestBy'] ?? json['RequestBy']),
      reason: toInt(json['reason'] ?? json['Reason']),
      note: (json['note'] ?? json['Note'])?.toString() ?? '',
      shiftID: toInt(json['shiftID'] ?? json['ShiftID']),
      qty: toDouble(json['qty'] ?? json['Qty']),
      ignore: (json['ignore'] ?? json['Ignore'])?.toString() ?? '',
      createBy: (json['createBy'] ?? json['CreateBy'])?.toString() ?? '',
      updateBy: (json['updateBy'] ?? json['UpdateBy'])?.toString() ?? '',
      createDate: (json['createDate'] ?? json['CreateDate']) != null
          ? DateTime.tryParse(
              (json['createDate'] ?? json['CreateDate']).toString(),
            )
          : null,
      docType: (json['docType'] ?? json['DocType'])?.toString() ?? 'OTDocType',
      siteID: (json['siteID'] ?? json['SiteID'])?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'status': status,
      'fromDate': fromDate.toIso8601String(),
      'toDate': toDate.toIso8601String(),
      'requestBy': requestBy,
      'reason': reason,
      'note': note,
      'shiftID': shiftID,
      'qty': qty,
      'ignore': ignore,
      'createBy': createBy,
      'updateBy': updateBy,
      'docType': docType,
      'siteID': siteID,
      if (id != null) 'id': id,
    };
  }

  @override
  String toString() =>
      'OvertimeRequest(id: $id, requestBy: $requestBy, shiftID: $shiftID, qty: $qty, status: $status)';

  static DateTime _parseTime(dynamic value) {
    if (value == null) return DateTime.now();
    try {
      final str = value.toString();
      if (!str.contains('T')) {
        return DateTime.parse(str);
      }

      // Extract time from the API exactly as sent without guessing the offsets
      // If the backend sends 00:00:00 Local time, this will parse to 00:00
      final dt = DateTime.parse(str);
      return dt.toLocal();
    } catch (_) {
      return DateTime.now();
    }
  }
}
