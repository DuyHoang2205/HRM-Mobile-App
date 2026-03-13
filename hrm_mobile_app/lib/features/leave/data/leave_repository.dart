import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../core/auth/auth_helper.dart';
import '../../../core/network/dio_client.dart';
import '../models/approve_leave_request.dart';
import '../models/leave_request.dart';
import '../models/permission_type_item.dart';

/// Repository xử lý toàn bộ các API call liên quan đến chức năng Nghỉ Phép.
/// Đây là "Data Layer" duy nhất tương tác với Backend, BLoC sẽ gọi vào đây.
class LeaveRepository {
  final DioClient _client;

  LeaveRepository({DioClient? client}) : _client = client ?? DioClient();

  // ---------------------------------------------------------------------------
  // DUYỆT / TỪ CHỐI ĐƠN NGHỈ PHÉP
  // ---------------------------------------------------------------------------

  /// Duyệt hoặc từ chối một đơn nghỉ phép.
  ///
  /// Endpoint: POST /api/approveProgress/changeStatus
  ///
  /// [docID]  → ID đơn cần duyệt
  /// [status] → dùng [LeaveApprovalStatus.approved] (3), [LeaveApprovalStatus.rejected] (4)
  ///
  /// [createdBy] và [siteID] tự động lấy từ session — không cần truyền vào.
  Future<bool> approveLeaveById({
    required int docID,
    required int status,
    String stepType = 'APPROVE',
  }) async {
    // Lấy thông tin người duyệt từ session
    final staffCode = await AuthHelper.getStaffCode() ?? 'admin';
    final siteId = await AuthHelper.getSiteId();

    final request = ApproveLeaveRequest(
      listDocID: [docID],
      status: status,
      createdBy: staffCode,
      siteID: siteId,
      stepType: stepType,
    );

    return approveLeaveRequest(request);
  }

  /// Gửi ApproveLeaveRequest đã được build sẵn.
  Future<bool> approveLeaveRequest(ApproveLeaveRequest request) async {
    try {
      final body = request.toJson();
      debugPrint(
        '[LeaveRepository] POST /approveProgress/changeStatus body: $body',
      );

      final response = await _client.dio.post(
        '/approveProgress/changeStatus',
        data: body,
      );

      debugPrint('[LeaveRepository] approve response: ${response.statusCode}');

      // SP trả về plain text 'OK', không phải JSON
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }

      final message = _extractMessage(response.data) ?? 'Duyệt thất bại';
      throw Exception(message);
    } on DioException catch (e) {
      final serverMessage = _extractMessage(e.response?.data);
      final message = serverMessage ?? e.message ?? 'Lỗi kết nối máy chủ';
      debugPrint('[LeaveRepository] DioException approve: $message');
      throw Exception(message);
    }
  }

  // ---------------------------------------------------------------------------
  // LẤY DANH SÁCH ĐƠN NGHỈ PHÉP CỦA NHÂN VIÊN
  // ---------------------------------------------------------------------------

  /// Lấy danh sách đơn nghỉ phép của một nhân viên theo năm.
  ///
  /// Endpoint: GET /api/onLeaveFileLine/:employeeID/:year/:site
  /// Calls EXEC OnLeaveFileLine_GetByEmployee
  Future<List<LeaveRequest>> getLeaveRequests({
    required int employeeID,
    required int year,
    required String siteID,
  }) async {
    try {
      debugPrint(
        '[LeaveRepository] GET /onLeaveFileLine/$employeeID/$year/$siteID',
      );
      final response = await _client.dio.get(
        'onLeaveFileLine/$employeeID/$year/$siteID',
      );

      if (response.statusCode == 200) {
        final List<dynamic> raw = response.data as List? ?? [];
        debugPrint('[LeaveRepo] Fetched ${raw.length} leaves');
        return raw
            .cast<Map<String, dynamic>>()
            .map(LeaveRequest.fromJson)
            .toList();
      }
      debugPrint('[LeaveRepo] Failed status: ${response.statusCode}');
      return [];
    } on DioException catch (e) {
      final message =
          _extractMessage(e.response?.data) ?? 'Lỗi khi tải danh sách';
      throw Exception(message);
    }
  }

  // ---------------------------------------------------------------------------
  // CÔNG TÁC (MOBILE-FIRST)
  // ---------------------------------------------------------------------------
  Future<List<LeaveRequest>> getBusinessTripRequests({
    required int employeeID,
    required int year,
    required String siteID,
  }) async {
    try {
      debugPrint(
        '[LeaveRepository] GET /businessTripMobile/$employeeID/$year/$siteID',
      );
      final response = await _client.dio.get(
        '/businessTripMobile/$employeeID/$year/$siteID',
      );
      if (response.statusCode == 200) {
        final List<dynamic> raw = response.data as List? ?? [];
        return raw
            .cast<Map<String, dynamic>>()
            .map(LeaveRequest.fromJson)
            .toList();
      }
      return [];
    } on DioException catch (e) {
      // Fallback an toàn: backend cũ chưa có route mới.
      debugPrint(
        '[LeaveRepository] businessTripMobile unavailable, fallback onLeaveFileLine: ${e.message}',
      );
      final all = await getLeaveRequests(
        employeeID: employeeID,
        year: year,
        siteID: siteID,
      );
      final permissionTypes = await getPermissionTypes(siteID);
      final cTypeIds = permissionTypes
          .where((t) => t.symbol.trim().toUpperCase() == 'C')
          .map((t) => t.id)
          .toSet();
      return all.where((r) => cTypeIds.contains(r.permissionType)).toList();
    }
  }

  Future<bool> submitBusinessTripRequest(Map<String, dynamic> body) async {
    try {
      debugPrint('[LeaveRepository] POST /businessTripMobile body: $body');
      final response = await _client.dio.post(
        '/businessTripMobile',
        data: body,
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      // Fallback an toàn: backend cũ chưa có route mới.
      debugPrint(
        '[LeaveRepository] businessTripMobile unavailable, fallback onLeaveFileLine: ${e.message}',
      );
      return submitLeaveRequest(body);
    }
  }

  // ---------------------------------------------------------------------------
  // GỬI ĐƠN NGHỈ PHÉP MỚI (Employee)
  // ---------------------------------------------------------------------------

  /// Gửi đơn xin nghỉ phép mới.
  ///
  /// Endpoint: POST /api/onLeaveFileLine
  Future<bool> submitLeaveRequest(Map<String, dynamic> body) async {
    try {
      debugPrint('[LeaveRepository] POST /onLeaveFileLine body: $body');

      final response = await _client.dio.post('/onLeaveFileLine', data: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }

      final message = _extractMessage(response.data) ?? 'Gửi đơn thất bại';
      throw Exception(message);
    } on DioException catch (e) {
      final message =
          _extractMessage(e.response?.data) ?? 'Lỗi kết nối máy chủ';
      throw Exception(message);
    }
  }

  // ---------------------------------------------------------------------------
  // DANH SÁCH LOẠI PHÉP (PermissionType)
  // ---------------------------------------------------------------------------

  /// Lấy danh sách loại phép theo site từ API thật.
  ///
  /// Endpoint: GET /api/permissionType/getAll/:siteID
  Future<List<PermissionTypeItem>> getPermissionTypes(String siteID) async {
    try {
      debugPrint('[LeaveRepository] GET /permissionType/getAll/$siteID');
      final response = await _client.dio.get('permissionType/getAll/$siteID');

      if (response.statusCode == 200) {
        final List<dynamic> raw = response.data as List? ?? [];
        return raw
            .cast<Map<String, dynamic>>()
            .map(PermissionTypeItem.fromJson)
            .toList();
      }
      return _fallbackPermissionTypes(siteID);
    } on DioException catch (e) {
      debugPrint('[LeaveRepository] Fallback permission types: ${e.message}');
      return _fallbackPermissionTypes(siteID);
    }
  }

  // ---------------------------------------------------------------------------
  // UTILITIES
  // ---------------------------------------------------------------------------

  /// Cố gắng trích xuất message lỗi từ response body theo nhiều format phổ biến của NestJS.
  String? _extractMessage(dynamic data) {
    if (data == null) return null;
    if (data is Map) {
      return (data['message'] ?? data['error'] ?? data['msg'])?.toString();
    }
    if (data is String && data.isNotEmpty) return data;
    return null;
  }

  List<PermissionTypeItem> _fallbackPermissionTypes(String siteID) {
    if (siteID.trim().toUpperCase() != 'KIA') return const [];

    return const [
      PermissionTypeItem(
        id: 25,
        permissionType: 'Công Tác',
        code: 'CT',
        siteID: 'KIA',
        symbol: 'CT',
      ),
      PermissionTypeItem(
        id: 28,
        permissionType: 'Nghỉ bù',
        code: 'NB',
        siteID: 'KIA',
        symbol: 'NB',
      ),
      PermissionTypeItem(
        id: 29,
        permissionType: 'Nghỉ không lương ( có xin phép)',
        code: 'KL',
        siteID: 'KIA',
        symbol: 'KL',
      ),
      PermissionTypeItem(
        id: 30,
        permissionType: 'Nghỉ không lương ( không xin phép)',
        code: 'KP',
        siteID: 'KIA',
        symbol: 'KP',
      ),
      PermissionTypeItem(
        id: 31,
        permissionType: 'Lễ',
        code: 'L',
        siteID: 'KIA',
        symbol: 'L',
      ),
      PermissionTypeItem(
        id: 34,
        permissionType: 'Công online',
        code: 'ON',
        siteID: 'KIA',
        symbol: 'ON',
      ),
      PermissionTypeItem(
        id: 35,
        permissionType: 'Nghỉ phép nữa ngày/ nữa ngày không công',
        code: 'F/2',
        siteID: 'KIA',
        symbol: 'F/2',
      ),
      PermissionTypeItem(
        id: 36,
        permissionType: 'Nghỉ phép nữa ngày nữa ngày có công',
        code: 'F/X',
        siteID: 'KIA',
        symbol: 'F/X',
      ),
      PermissionTypeItem(
        id: 37,
        permissionType: 'Nghỉ phép nữa ngày/nữa ngày công tác',
        code: 'F/CT',
        siteID: 'KIA',
        symbol: 'F/CT',
      ),
    ];
  }
}
