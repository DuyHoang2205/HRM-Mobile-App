import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'attendance_event.dart';
import 'attendance_state.dart';
import '../models/attendance_log.dart';
import '../models/daily_summary.dart';
import '../../../core/utils/attendance_action_resolver.dart';
import '../../../core/utils/attendance_day_policy.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/auth/auth_helper.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  static const int _shiftServerHourCompensation = 1;
  final DioClient _dioClient = DioClient();

  AttendanceBloc() : super(AttendanceState.initial()) {
    on<AttendanceStarted>(_onLoad);
    on<AttendanceRefreshed>(_onLoad);
    on<AttendanceFilterChanged>(_onFilterChanged);
    on<AttendanceCheckResultArrived>(_onLoad);
  }

  Future<void> _onFilterChanged(
    AttendanceFilterChanged event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(
      state.copyWith(
        filterDate: event.start,
        endDate: event.end,
        isLoading: true,
      ),
    );
    await _fetchLogs(emit);
  }

  Future<void> _onLoad(
    AttendanceEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    await _fetchLogs(emit);
  }

  Future<void> _fetchLogs(Emitter<AttendanceState> emit) async {
    emit(state.copyWith(isLoading: true));

    try {
      final employeeId = await AuthHelper.getEmployeeId();
      final siteID = await AuthHelper.getSiteId();
      final fullName = await AuthHelper.getFullName() ?? 'Trung Nguyen';

      final start = state.filterDate;
      // queryEnd is inclusive for filtering
      final DateTime queryEnd = state.endDate ?? DateTime.now();

      String fmt(DateTime d) =>
          "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

      List<AttendanceLog> allLogs = [];
      Map<String, DailySummary> summariesMap = {};

      // 1. Fetch Daily Summaries for Timesheet UI (NEW API)
      try {
        final fFromDate = fmt(start);
        final fToDate = fmt(queryEnd);

        final summaryResponse = await _dioClient.dio.post(
          'attendance/summary/$siteID',
          data: {
            'employeeId': employeeId,
            'employeeID': employeeId,
            'fromDate': fFromDate,
            'toDate': fToDate,
            'month': start.month,
            'year': start.year,
          },
        );

        final raw = summaryResponse.data;
        final List<dynamic> list = raw is List
            ? raw
            : (raw is Map && raw['data'] is List)
            ? (raw['data'] as List)
            : const [];

        for (var item in list) {
          if (item is! Map) continue;
          final summary = DailySummary.fromJson(
            Map<String, dynamic>.from(item),
          );
          if (summary.date.isEmpty) continue;
          summariesMap[summary.date] = summary;
        }
      } catch (e) {
        debugPrint('Failed to fetch daily summaries: $e');
      }

      // 2. Fetch Raw Attendance Logs for Timeline UI (Existing logic)
      final daysDiff = queryEnd.difference(start).inDays;

      try {
        final fFromDate = fmt(start);
        final fToDate = fmt(queryEnd);

        final response = await _dioClient.dio.post(
          'attendance/byEmployee/$siteID',
          data: {
            'employeeId': employeeId,
            'fromDate': fFromDate,
            'toDate': fToDate,
          },
        );

        if (response.data is List) {
          final list = response.data as List;
          if (list.isNotEmpty) {
            allLogs = list
                .map(
                  (e) => AttendanceLog.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList();
          }
        }
      } catch (e) {
        debugPrint('byEmployee fallback to getScanByDay due to error: $e');
      }

      if (allLogs.isEmpty) {
        debugPrint(
          'byEmployee returned empty, using getScanByDay loop fallback',
        );
        List<Future<Response>> futures = [];
        for (int i = 0; i <= daysDiff; i++) {
          final date = start.add(Duration(days: i));
          futures.add(
            _dioClient.dio.post(
              'attendance/getScanByDay/$siteID',
              data: {'employeeID': employeeId, 'day': fmt(date)},
            ),
          );
        }

        final responses = await Future.wait(futures);
        for (final response in responses) {
          try {
            if (response.data is List) {
              final list = response.data as List;
              allLogs.addAll(
                list.map(
                  (e) => AttendanceLog.fromJson(Map<String, dynamic>.from(e)),
                ),
              );
            }
          } catch (e) {
            // ignore
          }
        }
      }

      final uniqueLogs = <AttendanceLog>[];
      for (var log in allLogs) {
        uniqueLogs.add(log);
      }
      allLogs = uniqueLogs;

      // Sort by timestamp desc
      allLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      final resolved = AttendanceActionResolver.resolve(allLogs);
      final finalLogs = resolved
          .map((log) => log.copyWith(userName: fullName))
          .toList();

      // Keep fetching dayPolicies for now if anything else depends on it
      final dayPolicies = await _fetchDayPolicies(
        employeeId: employeeId ?? 0,
        siteID: siteID,
        start: start,
        end: queryEnd,
      );

      emit(
        state.copyWith(
          logs: finalLogs,
          dayPolicies: dayPolicies,
          dailySummaries: summariesMap,
          isLoading: false,
          error: null,
        ),
      );
    } catch (e, s) {
      // Never let loading hang
      debugPrint('Attendance fetch error: $e');
      debugPrint(s.toString());

      emit(
        state.copyWith(
          isLoading: false,
          error: 'Không thể tải dữ liệu. Vui lòng thử lại.',
        ),
      );
    }
  }

  Future<Map<String, AttendancePolicyConfig>> _fetchDayPolicies({
    required int employeeId,
    required String siteID,
    required DateTime start,
    required DateTime end,
  }) async {
    if (employeeId <= 0) return const {};

    final result = <String, AttendancePolicyConfig>{};
    final days = end.difference(start).inDays;

    for (int i = 0; i <= days; i++) {
      final day = start.add(Duration(days: i));
      final dayStr =
          "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
      try {
        final response = await _dioClient.dio.post(
          'shift/getShiftByDay',
          data: {'employeeID': employeeId, 'date': dayStr, 'siteID': siteID},
        );
        final ok =
            (response.statusCode ?? 0) >= 200 &&
            (response.statusCode ?? 0) < 300;
        if (!ok || response.data is! List) continue;
        final rows = response.data as List;
        if (rows.isEmpty) continue;

        final row = Map<String, dynamic>.from(rows.first as Map);
        final minFromWorkTime = _durationFromHourDecimal(
          _toDouble(row['timeCalculate']) > 0
              ? _toDouble(row['timeCalculate'])
              : _toDouble(row['workTime']),
        );
        if (minFromWorkTime == null) continue;

        final breaks = <WorkBreakWindow>[];
        final breakStart = _parseBackendTime(
          (row['startBreak'] ?? row['StartBreak'])?.toString(),
        );
        final breakEnd = _parseBackendTime(
          (row['endBreak'] ?? row['EndBreak'])?.toString(),
        );
        if (breakStart != null && breakEnd != null) {
          breaks.add(
            WorkBreakWindow(
              startHour: breakStart.hour,
              startMinute: breakStart.minute,
              endHour: breakEnd.hour,
              endMinute: breakEnd.minute,
            ),
          );
        }

        result[dayStr] = AttendancePolicyConfig(
          minimumWorkDuration: minFromWorkTime,
          breakWindows: breaks,
        );
      } catch (_) {
        // ignore day-level policy fetch error, keep other dates working
      }
    }
    return result;
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  Duration? _durationFromHourDecimal(double hourValue) {
    if (hourValue <= 0) return null;
    final minutes = (hourValue * 60).round();
    return Duration(minutes: minutes);
  }

  DateTime? _parseBackendTime(String? timeStr) {
    if (timeStr == null || timeStr.trim().isEmpty) return null;
    final raw = timeStr.trim();
    final now = DateTime.now();
    try {
      if (raw.contains('T')) {
        final parsed = DateTime.parse(raw);
        final utcHour = parsed.toUtc().hour;
        final utcMinute = parsed.toUtc().minute;
        final utcSecond = parsed.toUtc().second;
        final todayUtc = DateTime.utc(
          now.year,
          now.month,
          now.day,
          utcHour,
          utcMinute,
          utcSecond,
        );
        return todayUtc.toLocal().add(
          const Duration(hours: _shiftServerHourCompensation),
        );
      }

      final match = RegExp(
        r'(\d{1,2}):(\d{2})(?::(\d{2}))?(?:\.\d+)?',
      ).firstMatch(raw);
      if (match == null) return null;

      final hour = int.parse(match.group(1)!);
      final minute = int.parse(match.group(2)!);
      final second = int.parse(match.group(3) ?? '0');
      return DateTime(now.year, now.month, now.day, hour, minute, second);
    } catch (_) {
      return null;
    }
  }
}
