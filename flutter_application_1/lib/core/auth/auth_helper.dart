import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keys for stored auth data.
const String _kAccessToken = 'access_token';
const String _kRefreshToken = 'refresh_token';
const String _kEmployeeId = 'employee_id';
const String _kSiteId = 'site_id';

/// Decodes JWT payload (middle part) and returns payload map.
/// Returns null if token is invalid or missing.
Map<String, dynamic>? decodeJwtPayload(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    final payload = parts[1];
    // Base64Url decode (add padding if needed)
    var normalized = payload.replaceAll('-', '+').replaceAll('_', '/');
    switch (normalized.length % 4) {
      case 2:
        normalized += '==';
        break;
      case 3:
        normalized += '=';
        break;
    }
    final decoded = utf8.decode(base64Url.decode(normalized));
    return jsonDecode(decoded) as Map<String, dynamic>?;
  } catch (_) {
    return null;
  }
}

// real implementation
//   class AuthHelper {
//   /// Saves access token and, if present, employeeId and site from JWT payload.
//   static Future<void> saveTokenAndUser(String accessToken) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString(_kAccessToken, accessToken);
//     final payload = decodeJwtPayload(accessToken);
//     if (payload != null) {
//       final employeeId = payload['employeeId'];
//       if (employeeId != null) {
//         await prefs.setInt(_kEmployeeId, employeeId is int ? employeeId : int.tryParse(employeeId.toString()) ?? 0);
//       }
//       final site = payload['site'];
//       if (site != null) {
//         await prefs.setString(_kSiteId, site.toString());
//       }
//     }
//   }

//   /// Returns stored employee ID, or null if not set.
//   static Future<int?> getEmployeeId() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getInt(_kEmployeeId);
//   }

//   /// Returns stored site ID for API (e.g. byEmployee/:siteID). Defaults to 'MOBILE_APP'.
//   static Future<String> getSiteId() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString(_kSiteId) ?? 'MOBILE_APP';
//   }

//   static Future<void> clear() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove(_kAccessToken);
//     await prefs.remove(_kEmployeeId);
//     await prefs.remove(_kSiteId);
//   }
// }

class AuthHelper {
  static const String _kAccessToken = 'access_token';
  static const String _kRefreshToken = 'refresh_token';
  static const String _kEmployeeId = 'employee_id';
  static const String _kSiteId = 'site_id';
  static const String _kStaffCode = 'staff_code';
  static const String _kFullName = 'full_name';

  static const _storage = FlutterSecureStorage();

  /// Saves access token and, if present, employeeId and site from JWT payload.
  static Future<void> saveTokenAndUser(String accessToken) async {
    await _storage.write(key: _kAccessToken, value: accessToken);
    final payload = decodeJwtPayload(accessToken);
    if (payload != null) {
      final employeeId = payload['employeeId'];
      if (employeeId != null) {
        // Handle both string and int cases safely by saving as string
        final id = employeeId is int ? employeeId : int.tryParse(employeeId.toString()) ?? 0;
        await _storage.write(key: _kEmployeeId, value: id.toString());
      }
      final site = payload['site'];
      if (site != null) {
        await _storage.write(key: _kSiteId, value: site.toString());
      }
      final fullname = payload['admin'];
      if (fullname != null) {
        await _storage.write(key: _kFullName, value: fullname.toString());
      }
    }
  }

  static Future<void> saveRefreshToken(String refreshToken) async {
    await _storage.write(key: _kRefreshToken, value: refreshToken);
  }

  static Future<void> saveStaffCode(String staffCode) async {
    await _storage.write(key: _kStaffCode, value: staffCode);
  }

  /// Returns stored employee ID, or null if not set.
  static Future<int?> getEmployeeId() async {
    final value = await _storage.read(key: _kEmployeeId);
    return value != null ? int.tryParse(value) : null;
  }

  /// Returns stored site ID for API (e.g. byEmployee/:siteID). Defaults to 'MOBILE_APP'.
  static Future<String> getSiteId() async {
    final value = await _storage.read(key: _kSiteId);
    return value ?? 'MOBILE_APP';
  }
  
  static Future<String?> getStaffCode() async {
    return await _storage.read(key: _kStaffCode);
  }
  
  static Future<String?> getFullName() async {
    return await _storage.read(key: _kFullName);
  }
  
  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _kAccessToken);
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _kRefreshToken);
  }

  static Future<void> clear() async {
    await _storage.deleteAll(); // Clears everything including token
  }
}