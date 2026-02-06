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

  void _onFilterChanged(AttendanceFilterChanged event, Emitter<AttendanceState> emit) {
    emit(state.copyWith(filterDate: event.date));
    add(const AttendanceRefreshed());
  }

  void _onCheckResultArrived(AttendanceCheckResultArrived event, Emitter<AttendanceState> emit) {
    // Optimistic Update: Immediately flip the state
    // If we just Checked In (isCheckIn=true), then we ARE checked in.
    // If we just Checked Out (isCheckIn=false), then we ARE checked out (isCheckedIn=false).
    
    // We can also optimistically append the log to the list so the UI shows it instantly!
    final newLog = AttendanceLog(
      id: -1, // Temporary ID
      userName: 'Bạn', // Or fetch from state/auth
      subtitle: 'Vào/Ra ca trên điện thoại (Đang đồng bộ)',
      timestamp: event.timestamp,
      action: event.isCheckIn ? AttendanceAction.checkIn : AttendanceAction.checkOut,
    );
    
    final updatedLogs = List<AttendanceLog>.from(state.logs)..insert(0, newLog); // Add to top

    emit(state.copyWith(
      isCheckedIn: event.isCheckIn,
      logs: updatedLogs,
    ));
    
    // Still trigger a refresh to get the real data from server (and correct ID)
    add(const AttendanceRefreshed());
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
      final date = state.filterDate;
      final fromDate = DateTime(date.year, date.month, 1);
      // Use first day of NEXT month to ensure we cover the entire current month (including the last day)
      // because backend likely compares <= date (midnight) or similar.
      final toDate = DateTime(date.year, date.month + 1, 1);
      final response = await _dioClient.dio.post(
        'attendance/byEmployee/$siteID',
        data: {
          'employeeId': employeeId,
          'fromDate': _formatDate(fromDate),
          'toDate': _formatDate(toDate),
        },
      );

      final List<dynamic> raw = response.data is List ? response.data as List : const [];
      var logs = raw.map((e) => AttendanceLog.fromJson(Map<String, dynamic>.from(e as Map))).toList();

      // Sort ASC by timestamp to calculate In/Out
      logs.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      print('DEBUG: AttendanceBloc fetched ${logs.length} logs');
      
      // Calculate In/Out actions
      // Logic: For each day, first is In, then Out, then In...
      // Or simply alternating across the whole list?
      // Better: Alternating per day.
      // Group logs by Day to reset logic daily
      final Map<String, List<AttendanceLog>> groupedByDay = {};
      for (final log in logs) {
        final key = _formatDate(log.timestamp);
        if (!groupedByDay.containsKey(key)) groupedByDay[key] = [];
        groupedByDay[key]!.add(log);
      }

      final processedLogs = <AttendanceLog>[];
      
      // Process each day independently
      for (final dateKey in groupedByDay.keys) {
        final dayLogs = groupedByDay[dateKey]!;
        bool isCheckInNext = true; // First log of the day is ALWAYS CheckIn
        print('DEBUG: Processing Day $dateKey - ${dayLogs.length} logs');

        for (final log in dayLogs) {
          final action = isCheckInNext ? AttendanceAction.checkIn : AttendanceAction.checkOut;
          processedLogs.add(log.copyWith(action: action));
          
          // Toggle expected next state
          isCheckInNext = !isCheckInNext;
        }
      }
      
      // Determine final state based on TODAY's log count to be consistent with HomeBloc
      // If today logs count is ODD -> Checked In. EVEN -> Checked Out.
      final now = DateTime.now();
      final todayKey = _formatDate(now);
      final todayLogs = groupedByDay[todayKey] ?? [];
      
      final isCheckedIn = todayLogs.length % 2 != 0;
      print('DEBUG: Today ($todayKey) Logs Count: ${todayLogs.length} -> isCheckedIn: $isCheckedIn');

      // Reverse for display (Newest first)
      final displayLogs = processedLogs.reversed.toList();

      emit(state.copyWith(
        logs: displayLogs, 
        isLoading: false,
        isCheckedIn: isCheckedIn,
      ));
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
