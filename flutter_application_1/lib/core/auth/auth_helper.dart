import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Keys for stored auth data.
const String _kAccessToken = 'access_token';
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

class AuthHelper {
  /// Saves access token and, if present, employeeId and site from JWT payload.
  static Future<void> saveTokenAndUser(String accessToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccessToken, accessToken);
    final payload = decodeJwtPayload(accessToken);
    if (payload != null) {
      final employeeId = payload['employeeId'];
      if (employeeId != null) {
        await prefs.setInt(_kEmployeeId, employeeId is int ? employeeId : int.tryParse(employeeId.toString()) ?? 0);
      }
      final site = payload['site'];
      if (site != null) {
        await prefs.setString(_kSiteId, site.toString());
      }
    }
  }

  /// Returns stored employee ID, or null if not set.
  static Future<int?> getEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kEmployeeId);
  }

  /// Returns stored site ID for API (e.g. byEmployee/:siteID). Defaults to 'MOBILE_APP'.
  static Future<String> getSiteId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kSiteId) ?? 'MOBILE_APP';
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAccessToken);
    await prefs.remove(_kEmployeeId);
    await prefs.remove(_kSiteId);
  }
}
