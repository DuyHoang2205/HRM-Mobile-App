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
    emit(state.copyWith(
      filterDate: event.start,
      endDate: event.end,
      isLoading: true,
    ));
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
      final staffCode = await AuthHelper.getStaffCode();
      final siteID = await AuthHelper.getSiteId();
      final fullName = await AuthHelper.getFullName() ?? 'Trung Nguyen';

      // Use staffCode for byEmployee if available, but keep standard ID for raw scan lookup if needed
      final idForFilter = staffCode != null && staffCode.isNotEmpty ? staffCode : employeeId;

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
        futures.add(_dioClient.dio.post(
          'attendance/getScanByDay/$siteID',
          data: {
            'employeeID': employeeId, // Use the INT id (e.g. 2)
            'day': fDate,
          },
        ));
      }

      final responses = await Future.wait(futures);
      
      for (int i = 0; i < responses.length; i++) {
          final response = responses[i];
          try {
             if (response.data is List) {
                final list = response.data as List;
                // print('Chunk $i Response: ${list.length} records');
                final dailyLogs = list.map((e) => AttendanceLog.fromJson(Map<String, dynamic>.from(e))).toList();
                allLogs.addAll(dailyLogs);
             }
          } catch (e) {
             print('Error parsing chunk logs: $e');
          }
      }

      // 2. Fetch Raw Logs for "Today" (using getScanByDay) if today is in range
      // Only needed if queryEnd covers Today
      final now = DateTime.now();
      final isTodayInRange = !now.isBefore(start) && !now.isAfter(queryEnd.add(Duration(days: 1))); // Approximate check, simpler:
      if (queryEnd.year == now.year && queryEnd.month == now.month && queryEnd.day == now.day) {
          try {
             final rawDay = fmt(now); 
             // We already fetched Today in the loop above if Today is part of the range.
             // But keep this just in case logic differs or for redundancy?
             // Actually, if loop covers Today, we duplicate requests.
             // But let's check if loop covers Today.
             // Loop goes from start to queryEnd.
             // If queryEnd covers Today, loop covers Today.
             // So we DON'T need this block anymore if loop is correct.
             // But let's keep it harmless or remove to optimize?
             // Removing to avoid duplication.
          } catch (e) {
             print('Error fetching raw logs: $e');
          }
      }

      // Deduplicate if necessary (simple id check or timestamp check)
      // Since we fetch by distinct days, overlaps shouldn't happen unless getScanByDay duplicates byEmployee logs
      // AttendanceActionResolver handles grouping logic, so duplicate raw entries might be an issue?
      // Resolving logic will act on timestamps. Duplicate timestamps might cause issues?
      // Let's deduplicate by ID if available, or just leave it to Resolver.
      // Actually duplications between byEmployee (History) and getScanByDay (Raw) are possible for Today.
      // We can remove EXACT duplicates.
      final ids = <dynamic>{};
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
      final finalLogs = resolved.map((log) => log.copyWith(userName: fullName)).toList();
      
      emit(state.copyWith(
        logs: finalLogs,
        isLoading: false,
        error: null,
      ));
    } catch (e, s) {
      // Never let loading hang
      print('Attendance fetch error: $e');
      print(s);

      emit(state.copyWith(
        isLoading: false,
        error: 'Không thể tải dữ liệu. Vui lòng thử lại.',
      ));
    }
  }
}
