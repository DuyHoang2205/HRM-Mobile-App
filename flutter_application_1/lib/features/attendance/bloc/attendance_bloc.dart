import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/auth/auth_helper.dart';
import '../../../core/network/dio_client.dart';
import '../models/attendance_log.dart';
import 'attendance_event.dart';
import 'attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final DioClient _dioClient = DioClient();

  AttendanceBloc() : super(const AttendanceState(logs: [])) {
    on<AttendanceStarted>(_onLoad);
    on<AttendanceRefreshed>(_onLoad);
  }

  Future<void> _onLoad(
    AttendanceEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    final employeeId = await AuthHelper.getEmployeeId();
    if (employeeId == null) {
      emit(state.copyWith(logs: [], error: 'Chưa đăng nhập.'));
      return;
    }

    emit(state.copyWith(isLoading: true, error: null));
    try {
      final siteID = await AuthHelper.getSiteId();
      final now = DateTime.now();
      final fromDate = DateTime(now.year, now.month, 1);
      final toDate = DateTime(now.year, now.month + 1, 0);
      final response = await _dioClient.dio.post(
        '/attendance/byEmployee/$siteID',
        data: {
          'employeeId': employeeId,
          'fromDate': _formatDate(fromDate),
          'toDate': _formatDate(toDate),
        },
      );

      final List<dynamic> raw = response.data is List ? response.data as List : const [];
      final logs = raw.map((e) => AttendanceLog.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      emit(state.copyWith(logs: logs, isLoading: false));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('DioException [unknown]: ', ''),
      ));
    }
  }

  static String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
