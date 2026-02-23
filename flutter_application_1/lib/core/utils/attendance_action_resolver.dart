import '../../features/attendance/models/attendance_log.dart';

class AttendanceActionResolver {
  static List<AttendanceLog> resolve(List<AttendanceLog> logs) {
    if (logs.isEmpty) return [];

    // 1. Deduplicate by ID and Timestamp to prevent double-counting 
    // from the two API calls in HomeBloc
    final Map<String, AttendanceLog> uniqueLogs = {};
    for (var log in logs) {
      final key = "${log.timestamp.millisecondsSinceEpoch}-${log.id}";
      uniqueLogs[key] = log;
    }

    final sorted = uniqueLogs.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // 2. Group by Date
    final Map<String, List<AttendanceLog>> grouped = {};
    for (var log in sorted) {
      final key = "${log.timestamp.year}-${log.timestamp.month}-${log.timestamp.day}";
      grouped.putIfAbsent(key, () => []).add(log);
    }

    final List<AttendanceLog> resolved = [];

    grouped.forEach((key, dayLogs) {
      for (int i = 0; i < dayLogs.length; i++) {
        final log = dayLogs[i];
        final dir = log.direction?.toUpperCase();

        AttendanceAction action;
        // Apply your specific hardware/backend logic
        if (dir == 'OUT' || dir == '0') {
          action = AttendanceAction.checkIn;
        } else if (dir == 'IN' || dir == '1') {
          action = AttendanceAction.checkOut;
        } else {
          // If no direction, index 0 is In, index 1 is Out, etc.
          action = (i % 2 == 0) ? AttendanceAction.checkIn : AttendanceAction.checkOut;
        }
        
        resolved.add(log.copyWith(action: action));
      }
    });

    return resolved..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
}