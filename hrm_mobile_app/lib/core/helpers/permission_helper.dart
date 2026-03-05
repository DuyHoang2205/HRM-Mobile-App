import 'package:flutter/foundation.dart';
import '../network/dio_client.dart';
import '../auth/auth_helper.dart';
import 'dart:convert';

/// Cache in-memory – đủ dùng cho 1 session, reset khi logout
final Map<String, List<String>> _cache = {};

class PermissionHelper {
  static final DioClient _dioClient = DioClient();

  /// Lấy username từ secure storage hoặc decode thẳng từ JWT token
  static Future<String?> _getUsername() async {
    // Thử lấy từ storage trước (nếu đã login sau khi code mới)
    final stored = await AuthHelper.getUserName();
    if (stored != null && stored.isNotEmpty) return stored;

    // Fallback: decode từ JWT token trực tiếp
    final token = await AuthHelper.getAccessToken();
    if (token == null) return null;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      switch (payload.length % 4) {
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
      }
      final decoded = jsonDecode(utf8.decode(base64Url.decode(payload)));
      final username = decoded['username']?.toString();
      // Lưu lại để lần sau dùng
      if (username != null) {
        await AuthHelper.saveTokenAndUser(token);
      }
      return username;
    } catch (e) {
      debugPrint('[PermissionHelper] Cannot decode JWT: $e');
      return null;
    }
  }

  /// Trả về danh sách rule mà user hiện tại có trên [formName].
  /// Ví dụ: ['Add', 'Edit', 'Delete', 'View']
  static Future<List<String>> getRules(String formName) async {
    try {
      final username = await _getUsername();
      final siteId = await AuthHelper.getSiteId();
      final cacheKey = '$formName|$username|$siteId';

      if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;

      debugPrint(
        '[PermissionHelper] Checking $formName for user=$username site=$siteId',
      );

      if (username == null || username.isEmpty) {
        debugPrint(
          '[PermissionHelper] username is null, cannot check permissions',
        );
        return [];
      }

      // Path KHÔNG có dấu / đầu và dùng đúng case của router backend: userRole/getRoleByUser
      final response = await _dioClient.dio.post(
        'userRole/getRoleByUser',
        data: {'formName': formName, 'userName': username, 'siteID': siteId},
      );

      debugPrint('[PermissionHelper] Response status: ${response.statusCode}');
      debugPrint('[PermissionHelper] Response data: ${response.data}');

      final data = response.data;
      if (data is List) {
        final rules = data
            .map((e) => (e['RuleNo_'] ?? e['ruleNo_'] ?? '').toString())
            .where((r) => r.isNotEmpty)
            .toList();
        _cache[cacheKey] = rules;
        debugPrint('[PermissionHelper] $formName → $rules');
        return rules;
      }
    } catch (e) {
      debugPrint('[PermissionHelper] Error checking $formName: $e');
    }
    return [];
  }

  /// Kiểm tra user có quyền cụ thể trên form không
  static Future<bool> can(String formName, String rule) async {
    final rules = await getRules(formName);
    return rules.contains(rule);
  }

  /// Kiểm tra có thể tạo mới overtime không (Add permission)
  static Future<bool> canAddOvertime() => can('frmOvertime', 'Add');

  /// Xóa cache khi logout
  static void clearCache() => _cache.clear();
}
