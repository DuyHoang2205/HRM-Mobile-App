import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'home_event.dart';
import 'home_state.dart';
import '../../attendance/models/attendance_log.dart';
import '../../../core/utils/attendance_action_resolver.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/auth/auth_helper.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  Timer? _midnightTimer;
  final DioClient _dioClient = DioClient();

  HomeBloc() : super(HomeState.initial()) {
    on<HomeStarted>((event, emit) {
      _scheduleMidnightRefresh(emit);
      add(const AttendanceLogsRequested());
    });

    on<AttendanceLogsRequested>(_onAttendanceLogsRequested);

    // on<CheckResultArrived>((event, emit) {
    //   // Optimistic Flip
    //   if (event.isCheckIn) {
    //     emit(state.copyWith(checkedInAt: event.timestamp, checkedOutAt: null));
    //   } else {
    //     emit(state.copyWith(checkedInAt: null, checkedOutAt: event.timestamp));
    //   }
    //   add(const AttendanceLogsRequested());
    // });

    on<CheckResultArrived>((event, emit) async {
      emit(state.copyWith(isLoading: true));
      try {
        // We verify credentials just in case, or we likely just want to refresh
        await AuthHelper.getEmployeeId();
        await AuthHelper.getSiteId();
        // Trigger a refresh of the logs which will reset isLoading to false when done
        add(const AttendanceLogsRequested());
      } catch (e) {
        emit(state.copyWith(isLoading: false));
      }
    });

    on<NotificationTapped>((event, emit) {
      // Handle notification tap (e.g. navigation or analytics)
      debugPrint('Notification tapped');
    });

    on<AttendanceLogsLoaded>((event, emit) {
      // Ensure the list is treated as AttendanceLog objects
      final List<AttendanceLog> rawLogs = event.logs;
      final resolvedLogs = AttendanceActionResolver.resolve(rawLogs);

      DateTime? lastCheckIn;
      DateTime? lastCheckOut;

      if (resolvedLogs.isNotEmpty) {
        final now = DateTime.now();
        // Use an explicit type in the where clause
        final todayLogs = resolvedLogs
            .where(
              (AttendanceLog log) =>
                  log.timestamp.year == now.year &&
                  log.timestamp.month == now.month &&
                  log.timestamp.day == now.day,
            )
            .toList();

        if (todayLogs.isNotEmpty) {
          final latest = todayLogs.first;
          if (latest.action == AttendanceAction.checkIn) {
            lastCheckIn = latest.timestamp;
            lastCheckOut = null;
          } else {
            lastCheckIn = latest.timestamp;
            lastCheckOut = latest.timestamp;
          }
        }
      }

      emit(
        state.copyWith(
          attendanceLogs: resolvedLogs,
          checkedInAt: lastCheckIn,
          checkedOutAt: lastCheckOut,
          isLoading: false,
        ),
      );
    });
  }

  Future<void> _onAttendanceLogsRequested(
    AttendanceLogsRequested event,
    Emitter<HomeState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true)); // Ensure loading state is shown

      final employeeId = await AuthHelper.getEmployeeId();
      final siteID = await AuthHelper.getSiteId();
      final fullName = await AuthHelper.getFullName() ?? 'Trung Nguyen';

      // Setup dynamic role and initials based on current user
      final role = fullName.contains('Bảo Duy')
          ? 'Software engineer'
          : 'Giám Đốc';
      String initials = fullName
          .split(' ')
          .where((e) => e.isNotEmpty)
          .map((e) => e[0])
          .take(2)
          .join()
          .toUpperCase();
      if (initials.isEmpty) initials = 'TN';

      emit(
        state.copyWith(
          isLoading: true,
          name: fullName,
          role: role,
          initials: initials,
        ),
      );

      final now = DateTime.now();
      String fmt(DateTime d) =>
          "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

      final List<AttendanceLog> logs = [];

      // --- OLD LOGIC (COMMENTED OUT DUE TO BACKEND LIMIT ISSUE) ---
      // Backend limits records to ~20-30, causing missing logs for wide date ranges (e.g. 30 days).
      // Keeping this for reference until Backend SP is fixed.
      /*
      // 1. Fetch Historical/Processed Logs
      try {
        final response = await _dioClient.dio.post(
          'attendance/byEmployee/$siteID',
          data: {
            'employeeId': idForFilter,
            'fromDate': fmt(now.subtract(const Duration(days: 30))),
            'toDate': fmt(now.add(const Duration(days: 1))),
          },
        );
        if (response.data is List) {
          logs.addAll((response.data as List).map((e) => AttendanceLog.fromJson(Map<String, dynamic>.from(e))));
        }
      } catch (e) {
        debugPrint('HomeBloc: Error fetching history: $e');
      }

      // 2. Fetch Today's Raw Logs (Real-time Check-in)
      try {
        final rawResponse = await _dioClient.dio.post(
          'attendance/getScanByDay/$siteID',
          data: {
            'employeeID': employeeId, // Must be int
            'day': fmt(now),
          },
        );
        if (rawResponse.data is List) {
          final rawLogs = (rawResponse.data as List).map((e) => AttendanceLog.fromJson(Map<String, dynamic>.from(e)));
          logs.addAll(rawLogs);
        }
      } catch (e) {
        debugPrint('HomeBloc: Error fetching raw logs: $e');
      }
      */
      // --- END OLD LOGIC ---

      // --- NEW WORKAROUND LOGIC (FETCH DAY BY DAY) ---

      // Calculate start of week (Monday)
      // DateTime.monday = 1. If today is Monday(1), subtract 0. If Tuesday(2), subtract 1.
      final int daysToSubtract = now.weekday - DateTime.monday;
      final DateTime startOfWeek = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: daysToSubtract));

      final List<Future<Response>> fetchFutures = [];

      // Fetch for 7 days of the current week (Mon-Sun)
      for (int i = 0; i < 7; i++) {
        final date = startOfWeek.add(Duration(days: i));
        // Only fetch up to today (optional, but good for performance if future dates have no data)
        // But schedule might need future dots? No, attendance is past.
        if (date.isAfter(now)) continue;

        fetchFutures.add(
          _dioClient.dio.post(
            'attendance/getScanByDay/$siteID',
            data: {'employeeID': employeeId, 'day': fmt(date)},
          ),
        );
      }

      final responses = await Future.wait(fetchFutures);

      for (final response in responses) {
        try {
          if (response.data is List) {
            final dailyLogs = (response.data as List)
                .map(
                  (e) => AttendanceLog.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList();

            // Note: dailyLogs might duplicate logs if we fetch overlapping ranges, but here we fetch distinct days.
            // However, if we combine with OLD LOGIC (which we aren't), we'd need deduplication.
            logs.addAll(dailyLogs);
          }
        } catch (e) {
          debugPrint('HomeBloc: Error parsing daily log: $e');
        }
      }
      // --- END NEW LOGIC ---

      final updatedLogs = logs
          .map((log) => log.copyWith(userName: fullName))
          .toList();
      add(AttendanceLogsLoaded(updatedLogs));
    } catch (e) {
      debugPrint('HomeBloc fetch error: $e');
      emit(state.copyWith(isLoading: false));
    }
  }

  void _scheduleMidnightRefresh(Emitter<HomeState> emit) {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));
    final duration = nextMidnight.difference(now) + const Duration(seconds: 2);
    _midnightTimer = Timer(duration, () {
      emit(state.copyWith(today: DateTime.now()));
      _scheduleMidnightRefresh(emit);
    });
  }

  @override
  Future<void> close() {
    _midnightTimer?.cancel();
    return super.close();
  }
}
