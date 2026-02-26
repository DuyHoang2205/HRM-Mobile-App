import 'package:flutter/foundation.dart';

enum AttendanceAction { checkIn, checkOut }

class AttendanceLog {
  final int id;
  final String userName;
  final DateTime timestamp;
  final AttendanceAction action;
  final String subtitle;
  final String? direction; // IN / OUT

  AttendanceLog({
    required this.id,
    required this.userName,
    required this.timestamp,
    required this.action,
    required this.subtitle,
    this.direction,
  });

  AttendanceLog copyWith({
    int? id,
    String? userName,
    DateTime? timestamp,
    AttendanceAction? action,
    String? subtitle,
    String? direction,
  }) {
    return AttendanceLog(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      timestamp: timestamp ?? this.timestamp,
      action: action ?? this.action,
      subtitle: subtitle ?? this.subtitle,
      direction: direction ?? this.direction,
    );
  }

  factory AttendanceLog.fromJson(Map<String, dynamic> json) {
    // 1. Try "AuthDate" + "AuthTime" (Old/Existing Format) or camelCase variants
    final authDate = json['AuthDate'] ?? json['authDate']; // yyyy-MM-dd
    final authTime = json['AuthTime'] ?? json['authTime']; // HH:mm:ss

    // 2. Try "attendanceTime" or "Time" (New/Table Format)
    final attendanceTime =
        json['attendanceTime'] ?? json['AttendanceTime'] ?? json['Time'];

    DateTime parsedTime;

    if (attendanceTime != null) {
      // Case A: Full ISO String or DateTime string
      try {
        parsedTime = DateTime.parse(attendanceTime.toString());
      } catch (_) {
        // Case B: Just Time string (e.g. "08:30:00"), assume Today or try to find Date
        // If we have a separate Date field, use it, otherwise use Today

        // PRIORITIZE 'day' from byEmployee API which handles historical dates correctly
        var rawDate =
            json['day'] ??
            json['Day'] ??
            json['Date'] ??
            json['AttendanceDate'] ??
            json['authDate'] ??
            json['AuthDate'];
        String datePart;

        if (rawDate != null) {
          datePart = rawDate.toString().split(
            'T',
          )[0]; // Handle ISO date strings (e.g. 2026-02-09T00:00:00.000Z)
        } else {
          datePart = DateTime.now().toIso8601String().split('T')[0];
        }

        try {
          // If attendanceTime is "1970-01-01T08:00:00.000Z", we should extract time only
          String timePart = attendanceTime.toString();
          if (timePart.contains('T')) {
            final dt = DateTime.parse(timePart);
            // Backend stores Time in UTC with +1h offset (e.g. 07:00Z for 14:00 VN)
            // We need to convert to Local and Subtract 1 hour to get correct HH:mm:ss
            final vietnamTime = dt.toLocal();
            final correctedTime = vietnamTime.subtract(
              const Duration(hours: 1),
            );
            timePart =
                "${correctedTime.hour.toString().padLeft(2, '0')}:${correctedTime.minute.toString().padLeft(2, '0')}:${correctedTime.second.toString().padLeft(2, '0')}";
          }

          parsedTime = DateTime.parse('${datePart}T$timePart');
        } catch (e) {
          debugPrint('Error parsing attendanceTime: $e');
          parsedTime = DateTime.now();
        }
      }
    } else if (authDate != null && authTime != null) {
      // Case C: AuthDate + AuthTime (Handle potential ISO strings)
      try {
        // 1. Parse Date Component
        DateTime datePart;
        final dStr = authDate.toString();
        if (dStr.contains('T')) {
          // Backend sends UTC time with Z marker, need to convert to Vietnam
          final parsedUTC = DateTime.parse(dStr);
          final vietnamDateTime = parsedUTC.toLocal();
          datePart = DateTime(
            vietnamDateTime.year,
            vietnamDateTime.month,
            vietnamDateTime.day,
          );
        } else {
          // Assume YYYY-MM-DD
          datePart = DateTime.parse("${dStr}T00:00:00");
        }

        // 2. Parse Time Component
        DateTime timePart;
        String tStr = authTime.toString();
        if (tStr.contains('T')) {
          // Backend sends UTC time, but TypeORM/MSSQL adds +1 hour during serialization
          // So we need to subtract 1 hour after converting to local
          final parsedUTC = DateTime.parse(tStr);
          final vietnamTime = parsedUTC.toLocal();
          final correctedTime = vietnamTime.subtract(const Duration(hours: 1));
          timePart = DateTime(
            1970,
            1,
            1,
            correctedTime.hour,
            correctedTime.minute,
            correctedTime.second,
          );
        } else {
          // Assume HH:mm or HH:mm:ss
          if (tStr.length == 5) tStr += ":00";
          timePart = DateTime.parse("1970-01-01T$tStr");
        }

        // 3. Combine -> Date from AuthDate + Time from AuthTime
        parsedTime = DateTime(
          datePart.year,
          datePart.month,
          datePart.day,
          timePart.hour,
          timePart.minute,
          timePart.second,
        );
      } catch (e) {
        debugPrint('Error parsing AuthDate/Time: $e');
        parsedTime = DateTime.now();
      }
    } else {
      // Fallback
      parsedTime = DateTime.now();
    }

    return AttendanceLog(
      id: json['ID'] ?? json['id'] ?? 0,
      userName: _resolveName(
        json['AttendCode']?.toString() ??
            json['attendCode']?.toString() ??
            json['EmployeeCode']?.toString() ??
            'Unknown',
      ),
      timestamp: parsedTime,
      action:
          AttendanceAction.checkIn, // Resolver will fix based on time/direction
      subtitle: 'Site ${json['Location'] ?? json['location'] ?? ''}',
      direction: json['direction'] ?? json['Direction'],
    );
  }

  static String _resolveName(String code) {
    if (code == '10132' || code == '2') return 'Trung Nguyen';
    return 'Trung Nguyen'; // For demo, always Trung Nguyen
  }
}
