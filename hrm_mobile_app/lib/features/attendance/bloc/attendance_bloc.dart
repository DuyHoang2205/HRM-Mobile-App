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

      // Attempt to load using the optimized byEmployee endpoint first
      // Note: Backend expects 'employeeId' (lowercase d), not 'employeeID' for this endpoint
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

      // If byEmployee returned empty (possibly due to Stored Procedure limits), fallback to day-by-day
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
