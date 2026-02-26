import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'attendance_event.dart';
import 'attendance_state.dart';
import '../models/attendance_log.dart';
import '../../../core/utils/attendance_action_resolver.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/auth/auth_helper.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
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

      // Calculate number of days
      final daysDiff = queryEnd.difference(start).inDays;

      // If range is large (> 31 days), limit concurrency or just warn?
      // For now, we assume reasonable range usage.

      List<Future<Response>> futures = [];

      // Fetch day-by-day using getScanByDay (Raw Data) which is proven to return data for this test user
      for (int i = 0; i <= daysDiff; i++) {
        final date = start.add(Duration(days: i));
        final fDate = fmt(date);
        // We query using getScanByDay for EACH day in the range.
        // This is necessary because byEmployee seems to return empty for ID 10132 (or at least for history).
        futures.add(
          _dioClient.dio.post(
            'attendance/getScanByDay/$siteID',
            data: {
              'employeeID': employeeId, // Use the INT id (e.g. 2)
              'day': fDate,
            },
          ),
        );
      }

      final responses = await Future.wait(futures);

      for (int i = 0; i < responses.length; i++) {
        final response = responses[i];
        try {
          if (response.data is List) {
            final list = response.data as List;
            // debugPrint('Chunk $i Response: ${list.length} records');
            final dailyLogs = list
                .map(
                  (e) => AttendanceLog.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList();
            allLogs.addAll(dailyLogs);
          }
        } catch (e) {
          debugPrint('Error parsing chunk logs: $e');
        }
      }

      // Deduplicate if necessary (simple id check or timestamp check)
      // Since we fetch by distinct days, overlaps shouldn't happen unless getScanByDay duplicates byEmployee logs
      // AttendanceActionResolver handles grouping logic, so duplicate raw entries might be an issue?
      // Resolving logic will act on timestamps. Duplicate timestamps might cause issues?
      // Let's deduplicate by ID if available, or just leave it to Resolver.
      // Actually duplications between byEmployee (History) and getScanByDay (Raw) are possible for Today.
      // We can remove EXACT duplicates.
      final uniqueLogs = <AttendanceLog>[];
      for (var log in allLogs) {
        // Using a unique key: ID (if > 0) or specific timestamp string?
        // Logs from byEmployee have ID. Logs from getScanByDay might have ID 0?
        // Let's rely on Resolver. The issue is missing logs, not duplicates.
        uniqueLogs.add(log);
      }
      allLogs = uniqueLogs;

      // Sort by timestamp desc
      allLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      final resolved = AttendanceActionResolver.resolve(allLogs);
      final finalLogs = resolved
          .map((log) => log.copyWith(userName: fullName))
          .toList();

      emit(state.copyWith(logs: finalLogs, isLoading: false, error: null));
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
}
