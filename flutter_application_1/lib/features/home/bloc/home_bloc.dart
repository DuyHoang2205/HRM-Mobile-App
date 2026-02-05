import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'home_event.dart';
import 'home_state.dart';
import '../../attendance/models/attendance_log.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  Timer? _midnightTimer;

  HomeBloc() : super(HomeState.initial()) {
    on<HomeStarted>((event, emit) {
      _scheduleMidnightRefresh(emit);
    });

    on<NotificationTapped>((event, emit) {
      // later: navigate to notifications
    });

    on<CheckInTapped>((event, emit) {
      // No-op: actual API is called in CheckInBloc. Callers use CheckResultArrived with result.
    });

    on<CheckResultArrived>((event, emit) {
      if (event.isCheckIn) {
        emit(state.copyWith(
          checkedInAt: event.timestamp,
          checkedOutAt: null,
        ));
      } else {
        emit(state.copyWith(checkedOutAt: event.timestamp));
      }
    });

    on<AttendanceLogsLoaded>((event, emit) {
      DateTime? lastCheckIn;
      DateTime? lastCheckOut;

      // Logic to sync check-in status from logs
      if (event.logs.isNotEmpty) {
        // Find the LATEST log for TODAY (or overall, depending on logic)
        // Since event.logs contains last 30 days, we should look for the latest log.
        // Assuming logs are sorted (or we sort them here)
        final sortedLogs = List<AttendanceLog>.from(event.logs)
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Newest first

        final latest = sortedLogs.first;
        final today = DateTime.now();

        // Only update status if the log is from TODAY (or recently? Shift logic...)
        // For simplicity, if the latest log is today, we respect it.
        // If the latest log is checkIn -> we are checked in.
        // If the latest log is checkOut -> we are checked out.

        // Filter logs for today
        final todayLogs = sortedLogs.where((log) => 
          log.timestamp.year == today.year &&
          log.timestamp.month == today.month &&
          log.timestamp.day == today.day
        ).toList();

        if (todayLogs.isNotEmpty) {
          // If count is ODD -> We are currently Checked IN (1st=In, 2nd=Out, 3rd=In...)
          // If count is EVEN -> We are currently Checked OUT
          
          final isCheckedIn = todayLogs.length % 2 != 0;
          final latest = todayLogs.first; // sortedLogs is desc, so this is latest

          if (isCheckedIn) {
            lastCheckIn = latest.timestamp;
            lastCheckOut = null;
          } else {
            // Checked out
            lastCheckIn = null;
            lastCheckOut = latest.timestamp;
          }
        }
      }

      emit(state.copyWith(
        attendanceLogs: event.logs,
        checkedInAt: lastCheckIn,  // Auto-sync status
        checkedOutAt: lastCheckOut,
      ));
    });
  }

  void _scheduleMidnightRefresh(Emitter<HomeState> emit) {
    _midnightTimer?.cancel();

    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final duration = nextMidnight.difference(now) + const Duration(seconds: 2); // small buffer

    _midnightTimer = Timer(duration, () {
      emit(state.copyWith(today: DateTime.now()));
      _scheduleMidnightRefresh(emit); // keep refreshing daily
    });
  }

  @override
  Future<void> close() {
    _midnightTimer?.cancel();
    return super.close();
  }
}
