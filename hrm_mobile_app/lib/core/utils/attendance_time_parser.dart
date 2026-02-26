import 'package:flutter/foundation.dart';
class AttendanceTimeParser {
  static DateTime parseDateTime({
    required dynamic date,
    dynamic time,
  }) {
    // 1. Handle null safety
    if (date == null) throw const FormatException('AuthDate is null');

    final dateStr = date.toString().trim();

    // CASE 1: Full ISO string (e.g., 2026-02-06T00:05:22.243Z)
    if (dateStr.contains('T')) {
      DateTime parsed = DateTime.parse(dateStr);
      
      // We add 14 hours because your server is sending 00:05 
      // when it is actually 14:05 in Vietnam.
      DateTime shifted = parsed.add(const Duration(hours: 14));

      debugPrint('--- TIMEZONE DEBUG ---');
      debugPrint('RAW FROM SERVER: $dateStr');
      debugPrint('FIXED RESULT (+14h): $shifted');
      debugPrint('----------------------');
      
      return shifted; 
    }

    // CASE 2: Split Date and Time strings (Fallback)
    final timeStr = (time == null || time.toString().trim().isEmpty)
        ? '00:00:00'
        : time.toString().trim();

    final dateParts = dateStr.split('-');
    final timeParts = timeStr.split(':');

    if (dateParts.length != 3 || timeParts.length < 2) {
      throw FormatException('Invalid format: $dateStr $timeStr');
    }

    // Create the date and add 14 hours to align with the ISO logic above
    return DateTime(
      int.parse(dateParts[0]), // year
      int.parse(dateParts[1]), // month
      int.parse(dateParts[2]), // day
      int.parse(timeParts[0]), // hour
      int.parse(timeParts[1]), // minute
    ).add(const Duration(hours: 14));
  }
}