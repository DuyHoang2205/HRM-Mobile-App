import '../../features/attendance/models/attendance_log.dart';

class DemoAttendanceStore {
  DemoAttendanceStore._();

  static final List<AttendanceLog> logs = [];

  static void add(AttendanceLog log) {
    logs.insert(0, log); // newest on top
  }
}
