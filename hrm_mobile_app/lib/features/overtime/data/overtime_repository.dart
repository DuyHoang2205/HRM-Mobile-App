import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../core/auth/auth_helper.dart';
import '../../../core/network/dio_client.dart';
import '../models/overtime_request.dart';
import '../models/shift_item.dart';
import '../models/employee_item.dart';
import '../models/attendance_record.dart';
import '../models/leave_record.dart';

/// Repository xử lý toàn bộ các API call liên quan đến Tăng ca (Overtime).
class OvertimeRepository {
  final DioClient _client;

  OvertimeRepository({DioClient? client}) : _client = client ?? DioClient();

  // ---------------------------------------------------------------------------
  // LẤY DANH SÁCH ĐƠN TĂNG CA CỦA NHÂN VIÊN
  // ---------------------------------------------------------------------------

  /// Endpoint: GET /api/decisionOvertime/:siteID
  /// [employeeId] = 0 → HR xem tất cả; có giá trị → lọc theo nhân viên
  Future<List<OvertimeRequest>> getOvertimeRequests({
    required int year,
    required String siteID,
    int employeeId = 0, // 0 = HR/xem tất cả
  }) async {
    try {
      debugPrint(
        '[OvertimeRepository] GET /decisionOvertime/$siteID (filter: employeeId=$employeeId, year=$year)',
      );
      final response = await _client.dio.get('/decisionOvertime/$siteID');
      if (response.statusCode == 200) {
        final List<dynamic> raw = response.data as List? ?? [];
        if (raw.isNotEmpty) {
          debugPrint('[OvertimeRepository] RAW FIRST ITEM: ${raw.first}');
        }
        return raw
            .cast<Map<String, dynamic>>()
            .map(OvertimeRequest.fromJson)
            .where((r) {
              final sameYear =
                  r.fromDate.year == year || r.createDate?.year == year;
              if (!sameYear) return false;
              // HR (employeeId=0) xem tất cả; Nhân viên chỉ xem của mình
              if (employeeId > 0) return r.requestBy == employeeId;
              return true;
            })
            .toList()
          ..sort((a, b) => b.fromDate.compareTo(a.fromDate));
      }
      return [];
    } on DioException catch (e) {
      final msg = _extractMessage(e.response?.data) ?? 'Lỗi khi tải danh sách';
      debugPrint('[OvertimeRepository] DioException getList: $msg');
      throw Exception(msg);
    }
  }

  // ---------------------------------------------------------------------------
  // LẤY DANH SÁCH NHÂN VIÊN (HR dropdown — giao ca cho ai)
  // ---------------------------------------------------------------------------

  /// Endpoint: GET /api/employee/list-employee?site=REEME
  /// Trả về danh sách nhân viên để HR chọn khi tạo phiếu tăng ca
  Future<List<EmployeeItem>> getEmployeeList(String siteID) async {
    try {
      debugPrint(
        '[OvertimeRepository] GET /employee/list-employee?site=$siteID',
      );
      final response = await _client.dio.get(
        '/employee/list-employee',
        queryParameters: {'site': siteID},
      );
      if (response.statusCode == 200) {
        final List<dynamic> raw = response.data as List? ?? [];
        return raw
            .cast<Map<String, dynamic>>()
            .map(EmployeeItem.fromJson)
            .where((e) => e.id > 0 && e.fullName.isNotEmpty)
            .toList()
          ..sort((a, b) => a.fullName.compareTo(b.fullName));
      }
      return [];
    } on DioException catch (e) {
      debugPrint('[OvertimeRepository] DioException getEmployeeList: $e');
      return []; // Không throw — HR vẫn dùng được dù list employee lỗi
    }
  }

  // ---------------------------------------------------------------------------
  // LẤY DANH SÁCH CA LÀM VIỆC (Dropdown)
  // ---------------------------------------------------------------------------

  /// Endpoint: GET /api/shift/getShiftOvertime/:siteID
  /// Chỉ lấy các ca thuộc loại "OT" để điền vào dropdown Tăng ca
  Future<List<ShiftItem>> getOvertimeShifts(String siteID) async {
    try {
      debugPrint('[OvertimeRepository] GET /shift/getShiftOvertime/$siteID');
      final response = await _client.dio.get('/shift/getShiftOvertime/$siteID');
      if (response.statusCode == 200) {
        final List<dynamic> raw = response.data as List? ?? [];
        return raw
            .cast<Map<String, dynamic>>()
            .map(ShiftItem.fromJson)
            .toList();
      }
      return [];
    } on DioException catch (e) {
      final msg =
          _extractMessage(e.response?.data) ?? 'Lỗi khi tải ca làm việc';
      debugPrint('[OvertimeRepository] DioException getShifts: $msg');
      throw Exception(msg);
    }
  }

  // ---------------------------------------------------------------------------
  // NỘP ĐƠN TĂNG CA MỚI
  // ---------------------------------------------------------------------------

  /// Endpoint: POST /api/decisionOvertime
  /// [createBy] và [requestBy] tự động lấy từ session (AuthHelper)
  Future<bool> submitOvertimeRequest(OvertimeRequest request) async {
    try {
      final body = request.toJson();
      debugPrint('[OvertimeRepository] POST /decisionOvertime body: $body');
      final response = await _client.dio.post('/decisionOvertime', data: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      final msg = _extractMessage(response.data) ?? 'Gửi đơn thất bại';
      throw Exception(msg);
    } on DioException catch (e) {
      final msg = _extractMessage(e.response?.data) ?? 'Lỗi kết nối máy chủ';
      debugPrint('[OvertimeRepository] DioException submit: $msg');
      throw Exception(msg);
    }
  }

  /// Lấy thông tin user hiện tại để auto-fill vào model khi submit
  Future<OvertimeRequest> buildRequestFromForm({
    required DateTime fromDate,
    required DateTime toDate,
    required int shiftID,
    required double qty,
    required String note,
    required String siteID,
  }) async {
    final employeeId = await AuthHelper.getEmployeeId() ?? 0;
    final staffCode = await AuthHelper.getStaffCode() ?? '';

    return OvertimeRequest(
      status: 0, // Chờ duyệt
      fromDate: fromDate,
      toDate: toDate,
      requestBy: employeeId,
      note: note,
      shiftID: shiftID,
      qty: qty,
      createBy: staffCode,
      updateBy: staffCode,
      siteID: siteID,
    );
  }

  // ---------------------------------------------------------------------------
  // CHẤM CÔNG (Attendance) — check "Hoàn thành" vs "Vắng không phép"
  // ---------------------------------------------------------------------------

  /// Endpoint: POST /api/attendance/byEmployee/:siteID
  /// [employeeId] = employeeId (INT), [fromDate]/[toDate] = "yyyy-MM-dd"
  Future<List<AttendanceRecord>> getAttendanceByEmployee({
    required String siteID,
    required int employeeId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      final from =
          '${fromDate.year}-${_pad(fromDate.month)}-${_pad(fromDate.day)}';
      final to = '${toDate.year}-${_pad(toDate.month)}-${_pad(toDate.day)}';
      debugPrint(
        '[OvertimeRepository] POST /attendance/byEmployee/$siteID ($from→$to)',
      );
      final response = await _client.dio.post(
        'attendance/byEmployee/$siteID',
        data: {'employeeId': employeeId, 'fromDate': from, 'toDate': to},
      );
      if (response.statusCode == 200) {
        final List<dynamic> raw = response.data as List? ?? [];
        return raw
            .cast<Map<String, dynamic>>()
            .map(AttendanceRecord.fromJson)
            .toList();
      }
      return [];
    } on DioException catch (e) {
      debugPrint('[OvertimeRepository] DioException getAttendance: $e');
      return []; // Không throw — vẫn hiển thị overtime dù không load đuợc chấm công
    }
  }

  // ---------------------------------------------------------------------------
  // NGHỈ PHÉP (Leave) — check "Nghỉ phép"
  // ---------------------------------------------------------------------------

  /// Endpoint: GET /api/onLeaveFileLine/:employeeID/:year/:siteID
  /// Trả về tất cả đơn nghỉ của NV trong năm hiện tại bằng endpoint không bị lỗi.
  /// (Lưu ý bên module leave, status 3 là Đã duyệt).
  Future<List<LeaveRecord>> getLeavesByEmployee({
    required String siteID,
    required int employeeId,
  }) async {
    try {
      final year = DateTime.now().year;
      debugPrint(
        '[OvertimeRepository] GET /onLeaveFileLine/$employeeId/$year/$siteID',
      );
      final response = await _client.dio.get(
        'onLeaveFileLine/$employeeId/$year/$siteID',
      );
      if (response.statusCode == 200) {
        final List<dynamic> raw = response.data as List? ?? [];
        return raw
            .cast<Map<String, dynamic>>()
            .map(LeaveRecord.fromJson)
            .toList();
      }
      return [];
    } on DioException catch (e) {
      debugPrint('[OvertimeRepository] DioException getLeaves: $e');
      return []; // Không throw
    }
  }

  // ---------------------------------------------------------------------------
  // UTILITIES
  // ---------------------------------------------------------------------------

  String _pad(int v) => v.toString().padLeft(2, '0');

  String? _extractMessage(dynamic data) {
    if (data == null) return null;
    if (data is Map) {
      return (data['message'] ?? data['error'] ?? data['msg'])?.toString();
    }
    if (data is String && data.isNotEmpty) return data;
    return null;
  }
}
