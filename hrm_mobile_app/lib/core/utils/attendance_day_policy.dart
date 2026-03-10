import '../../features/attendance/models/attendance_log.dart';

class WorkBreakWindow {
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  const WorkBreakWindow({
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
  });
}

class AttendancePolicyConfig {
  final Duration minimumWorkDuration;
  final List<WorkBreakWindow> breakWindows;

  const AttendancePolicyConfig({
    required this.minimumWorkDuration,
    this.breakWindows = const [
      WorkBreakWindow(startHour: 12, startMinute: 0, endHour: 13, endMinute: 0),
    ],
  });
}

class AttendanceDayEvaluation {
  final DateTime date;
  final DateTime? firstIn;
  final DateTime? lastOut;
  final Duration workedDuration;
  final bool hasCompletePair;
  final bool meetsMinimum;

  const AttendanceDayEvaluation({
    required this.date,
    required this.firstIn,
    required this.lastOut,
    required this.workedDuration,
    required this.hasCompletePair,
    required this.meetsMinimum,
  });
}

class AttendanceDayPolicy {
  static AttendanceDayEvaluation evaluate({
    required DateTime date,
    required List<AttendanceLog> logs,
    AttendancePolicyConfig? config,
  }) {
    if (logs.isEmpty) {
      return AttendanceDayEvaluation(
        date: DateTime(date.year, date.month, date.day),
        firstIn: null,
        lastOut: null,
        workedDuration: Duration.zero,
        hasCompletePair: false,
        meetsMinimum: false,
      );
    }

    final sorted = [...logs]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (sorted.length < 2) {
      return AttendanceDayEvaluation(
        date: DateTime(date.year, date.month, date.day),
        firstIn: sorted.first.timestamp,
        lastOut: null,
        workedDuration: Duration.zero,
        hasCompletePair: false,
        meetsMinimum: false,
      );
    }

    final firstIn = sorted.first.timestamp;
    var lastOut = sorted.last.timestamp;
    if (lastOut.isBefore(firstIn)) {
      lastOut = lastOut.add(const Duration(days: 1));
    }

    var worked = lastOut.difference(firstIn);
    if (config != null) {
      for (final bw in config.breakWindows) {
        final breakStart = DateTime(
          firstIn.year,
          firstIn.month,
          firstIn.day,
          bw.startHour,
          bw.startMinute,
        );
        var breakEnd = DateTime(
          firstIn.year,
          firstIn.month,
          firstIn.day,
          bw.endHour,
          bw.endMinute,
        );
        if (breakEnd.isBefore(breakStart)) {
          breakEnd = breakEnd.add(const Duration(days: 1));
        }

        final overlapStart = firstIn.isAfter(breakStart) ? firstIn : breakStart;
        final overlapEnd = lastOut.isBefore(breakEnd) ? lastOut : breakEnd;
        if (overlapEnd.isAfter(overlapStart)) {
          worked -= overlapEnd.difference(overlapStart);
        }
      }
    }

    if (worked.isNegative) {
      worked = Duration.zero;
    }

    final meetsMinimum =
        config == null ? true : worked >= config.minimumWorkDuration;

    return AttendanceDayEvaluation(
      date: DateTime(date.year, date.month, date.day),
      firstIn: firstIn,
      lastOut: lastOut,
      workedDuration: worked,
      hasCompletePair: true,
      meetsMinimum: meetsMinimum,
    );
  }
}
