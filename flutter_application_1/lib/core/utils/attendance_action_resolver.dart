import '../../features/attendance/models/attendance_log.dart';

class AttendanceActionResolver {
  static List<AttendanceLog> resolve(List<AttendanceLog> logs) {
    if (logs.isEmpty) return [];

    // 1. Sort by time ascending (oldest first) to process chronologically
    final sorted = [...logs]..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // 2. Map to track the "first event" of each specific date
    final Map<String, List<AttendanceLog>> logsByDate = {};

    for (var log in sorted) {
      final dateKey = "${log.timestamp.year}-${log.timestamp.month}-${log.timestamp.day}";
      logsByDate.putIfAbsent(dateKey, () => []).add(log);
    }

    final List<AttendanceLog> resolved = [];

    // 3. Process each day independently
    logsByDate.forEach((date, dayLogs) {
      for (int i = 0; i < dayLogs.length; i++) {
        // RULE: The 1st, 3rd, 5th log of any day is ALWAYS a Check-In (Blue)
        final isVaoCa = i % 2 == 0; 
        
        resolved.add(dayLogs[i].copyWith(
          action: isVaoCa ? AttendanceAction.checkIn : AttendanceAction.checkOut,
        ));
      }
    });

    // 4. Return sorted by timestamp DESCENDING (newest first for UI)
    return resolved..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
}