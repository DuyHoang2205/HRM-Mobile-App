/// Model gửi request DUYỆT / TỪ CHỐI đơn nghỉ phép.
///
/// Endpoint: POST /api/approveProgress/changeStatus
/// SP: ApproveProgressSave
///
/// [createdBy] và [siteID] được lấy tự động từ session (AuthHelper),
/// không cần caller truyền vào thủ công.
class ApproveLeaveRequest {
  /// Danh sách ID đơn cần duyệt (thường chỉ 1 ID từ Mobile)
  final List<int> listDocID;

  /// Trạng thái cần set:
  ///   3 = Đã duyệt (production flow — 117 records trong DB)
  ///   4 = Từ chối
  ///   0 = Reopen / Hủy duyệt
  final int status;

  /// Phải là 'OLDocType' để SP xử lý đúng bảng OnLeaveFileLine
  final String docType;

  /// Bước duyệt: 'APPROVE' hoặc 'ReviewStep'
  final String stepType;

  /// Username/AccountID người đang duyệt (lấy từ AuthHelper.getStaffCode())
  final String createdBy;

  /// Mã site (lấy từ AuthHelper.getSiteId())
  final String siteID;

  const ApproveLeaveRequest({
    required this.listDocID,
    required this.status,
    required this.createdBy,
    required this.siteID,
    this.docType = 'OLDocType',
    this.stepType = 'APPROVE',
  });

  /// Body JSON gửi lên POST /api/approveProgress/changeStatus
  Map<String, dynamic> toJson() => {
    'listDocID': listDocID,
    'status': status,
    'docType': docType,
    'stepType': stepType,
    'createdBy': createdBy,
    'siteID': siteID,
  };

  @override
  String toString() =>
      'ApproveLeaveRequest(listDocID: $listDocID, status: $status, '
      'createdBy: $createdBy, siteID: $siteID)';
}

/// Các giá trị status hợp lệ khi approve/reject.
/// Dựa trên dữ liệu DB thực tế (confirmed 2026-03-04, site REEME).
class LeaveApprovalStatus {
  /// 3 = Đã duyệt (production flow, 117 records)
  static const int approved = 3;

  /// 4 = Từ chối
  static const int rejected = 4;

  /// 0 = Reopen / Hủy duyệt về Chờ duyệt
  static const int reopen = 0;
}
