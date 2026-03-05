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
    return OvertimeRequest(
      id: json['id'] as int?,
      code: json['code']?.toString() ?? '',
      status: (json['status'] as num?)?.toInt() ?? 0,
      fromDate: json['fromDate'] != null
          ? DateTime.parse(json['fromDate'].toString())
          : DateTime.now(),
      toDate: json['toDate'] != null
          ? DateTime.parse(json['toDate'].toString())
          : DateTime.now(),
      requestBy: (json['requestBy'] as num?)?.toInt() ?? 0,
      reason: (json['reason'] as num?)?.toInt() ?? 0,
      note: json['note']?.toString() ?? '',
      shiftID: (json['shiftID'] as num?)?.toInt() ?? 0,
      qty: (json['qty'] as num?)?.toDouble() ?? 0.0,
      ignore: json['ignore']?.toString() ?? '',
      createBy: json['createBy']?.toString() ?? '',
      updateBy: json['updateBy']?.toString() ?? '',
      createDate: json['createDate'] != null
          ? DateTime.tryParse(json['createDate'].toString())
          : null,
      docType: json['docType']?.toString() ?? 'OTDocType',
      siteID: json['siteID']?.toString() ?? '',
    );
  }

  /// Gửi lên POST /api/decisionOvertime.
  /// CHỈ chứa trường có thật, giống hệt schema Entity Backend.
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
}
