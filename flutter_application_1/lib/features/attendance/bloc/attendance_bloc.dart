import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/auth/auth_helper.dart';
import '../../../core/network/dio_client.dart';
import '../models/attendance_log.dart';
import 'attendance_event.dart';
import 'attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final DioClient _dioClient = DioClient();

  AttendanceBloc() : super(AttendanceState.initial()) {
    on<AttendanceStarted>(_onLoad);
    on<AttendanceRefreshed>(_onLoad);
    on<AttendanceFilterChanged>(_onFilterChanged);
    on<AttendanceCheckResultArrived>(_onCheckResultArrived);
  }

  // =========================
  // FILTER CHANGE
  // =========================
  void _onFilterChanged(
    AttendanceFilterChanged event,
    Emitter<AttendanceState> emit,
  ) {
    emit(state.copyWith(filterDate: event.date));
    add(const AttendanceRefreshed());
  }

  // =========================
  // CHECK IN / OUT RESULT
  // =========================
  void _onCheckResultArrived(
    AttendanceCheckResultArrived event,
    Emitter<AttendanceState> emit,
  ) {
    emit(state.copyWith(
      isCheckedIn: event.isCheckIn,
    ));

    // Always reload from backend
    add(const AttendanceRefreshed());
  }

  // =========================
  // LOAD / REFRESH LOGS
  // =========================
  Future<void> _onLoad(
    AttendanceEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    final employeeId = await AuthHelper.getEmployeeId();
    if (employeeId == null) {
      emit(state.copyWith(
        logs: [],
        error: 'Chưa đăng nhập.',
        isLoading: false,
      ));
      return;
    }

    emit(state.copyWith(isLoading: true, error: null));

    try {
      final siteID = await AuthHelper.getSiteId();
      final date = state.filterDate;

      final fromDate = DateTime(date.year, date.month, 1);
      final toDate = DateTime(date.year, date.month + 1, 1);

      final response = await _dioClient.dio.post(
        'attendance/byEmployee/$siteID',
        data: {
          'employeeId': employeeId,
          'fromDate': _formatDate(fromDate),
          'toDate': _formatDate(toDate),
        },
      );

      final List<dynamic> raw =
          response.data is List ? response.data as List : const [];

      final logs = raw
          .map((e) => AttendanceLog.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList();

      // Sort ASC for processing
      logs.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      // =========================
      // GROUP BY DAY
      // =========================
      final Map<String, List<AttendanceLog>> groupedByDay = {};

      for (final log in logs) {
        final key = _formatDate(log.timestamp);
        groupedByDay.putIfAbsent(key, () => []).add(log);
      }

      final processedLogs = <AttendanceLog>[];

      for (final dayKey in groupedByDay.keys) {
        final dayLogs = groupedByDay[dayKey]!;
        bool isCheckInNext = true;

        for (final log in dayLogs) {
          processedLogs.add(
            log.copyWith(
              action: isCheckInNext
                  ? AttendanceAction.checkIn
                  : AttendanceAction.checkOut,
            ),
          );
          isCheckInNext = !isCheckInNext;
        }
      }

      // =========================
      // TODAY CHECK-IN STATE
      // =========================
      final todayKey = _formatDate(DateTime.now());
      final todayLogs = groupedByDay[todayKey] ?? [];

      final isCheckedIn = todayLogs.length.isOdd;

      // Newest first for UI
      final displayLogs = processedLogs.reversed.toList();

      emit(state.copyWith(
        logs: displayLogs,
        isCheckedIn: isCheckedIn,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst(
              'DioException [unknown]: ',
              '',
            ),
      ));
    }
  }

  // =========================
  // HELPERS
  // =========================
  static String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
