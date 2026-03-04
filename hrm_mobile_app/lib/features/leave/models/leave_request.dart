/// Model tương ứng với bảng SQL `OnLeaveFileLine` (14 cột chuẩn).
/// Chỉ chứa các trường CÓ THẬT trong Datebase, không chứa virtual fields.
class LeaveRequest {
  /// ID bản ghi (null khi tạo mới, gửi khi UPDATE)
  final int? id;

  /// ID nhân viên
  final int employeeID;

  /// Trạng thái — DB: 0=Chờ duyệt, 3=Đã duyệt, 4=Từ chối
  final int status;

  /// ID loại phép (FK → PermissionType.ID)
  final int permissionType;

  final DateTime fromDate;
  final DateTime toDate;
  final DateTime expired;

  /// Số ngày nghỉ (decimal 10,4)
  final double qty;

  final int year;
  final String description;
  final String createBy;
  final String updateBy;
  final String siteID;

  /// Phải là 'OLDocType' để SP ApproveProgressSave nhận đúng
  final String docType;

  const LeaveRequest({
    this.id,
    required this.employeeID,
    required this.status,
    required this.permissionType,
    required this.fromDate,
    required this.toDate,
    required this.expired,
    required this.qty,
    required this.year,
    required this.description,
    required this.createBy,
    required this.updateBy,
    required this.siteID,
    required this.docType,
  });

  /// Đọc từ JSON response của API (kết quả trả về từ DB thuần khiết)
  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['id'] as int?,
      employeeID: (json['employeeID'] as num?)?.toInt() ?? 0,
      status: (json['status'] as num?)?.toInt() ?? 0,
      permissionType: (json['permissionType'] as num?)?.toInt() ?? 0,
      fromDate: json['fromDate'] != null
          ? DateTime.parse(json['fromDate'].toString())
          : DateTime.now(),
      toDate: json['toDate'] != null
          ? DateTime.parse(json['toDate'].toString())
          : DateTime.now(),
      expired: json['expired'] != null
          ? DateTime.parse(json['expired'].toString())
          : DateTime.now(),
      qty: (json['qty'] as num?)?.toDouble() ?? 0.0,
      year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
      description: json['description']?.toString() ?? '',
      createBy: json['createBy']?.toString() ?? '',
      updateBy: json['updateBy']?.toString() ?? '',
      siteID: json['siteID']?.toString() ?? '',
      docType: json['docType']?.toString() ?? 'OLDocType',
    );
  }

  /// Gửi lên POST /api/onLeaveFileLine.
  /// CHỈ chứa trường có thật, giống y hệt lúc GET.
  Map<String, dynamic> toJson() {
    return {
      'employeeID': employeeID,
      'status': status,
      'permissionType': permissionType,
      'fromDate': fromDate.toIso8601String(),
      'toDate': toDate.toIso8601String(),
      'expired': expired.toIso8601String(),
      'qty': qty,
      'year': year,
      'description': description,
      'createBy': createBy,
      'updateBy': updateBy,
      'siteID': siteID,
      'docType': docType,
      if (id != null) 'id': id,
    };
  }

  @override
  String toString() =>
      'LeaveRequest(id: $id, employeeID: $employeeID, permissionType: $permissionType, status: $status)';
}
