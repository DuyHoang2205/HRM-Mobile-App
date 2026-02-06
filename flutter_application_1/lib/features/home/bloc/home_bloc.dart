import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
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

    on<CheckResultArrived>((event, emit) {
      // Optimistic Flip
      if (event.isCheckIn) {
        emit(state.copyWith(checkedInAt: event.timestamp, checkedOutAt: null));
      } else {
        emit(state.copyWith(checkedInAt: null, checkedOutAt: event.timestamp));
      }
      add(const AttendanceLogsRequested()); 
    });

    on<AttendanceLogsLoaded>((event, emit) {
      DateTime? lastCheckIn;
      DateTime? lastCheckOut;
      
      final resolvedLogs = AttendanceActionResolver.resolve(event.logs);

      if (resolvedLogs.isNotEmpty) {
        final today = DateTime.now();
        // Look for today's logs specifically
        final todayLogs = resolvedLogs.where((log) => 
          log.timestamp.year == today.year &&
          log.timestamp.month == today.month &&
          log.timestamp.day == today.day
        ).toList();

        if (todayLogs.isNotEmpty) {
          // Newest log today (resolved as newest-first)
          final latestLog = todayLogs.first; 
          
          if (latestLog.action == AttendanceAction.checkIn) {
            lastCheckIn = latestLog.timestamp;
            lastCheckOut = null;
          } else {
            lastCheckIn = null;
            lastCheckOut = latestLog.timestamp;
          }
        } else {
          // If no logs today, reset to Blue (Vào ca)
          lastCheckIn = null;
          lastCheckOut = null;
        }
      }

      emit(state.copyWith(
        attendanceLogs: resolvedLogs,
        checkedInAt: lastCheckIn,  
        checkedOutAt: lastCheckOut,
        isLoading: false,
      ));
    });
  }

  Future<void> _onAttendanceLogsRequested(AttendanceLogsRequested event, Emitter<HomeState> emit) async {
    try {
      final employeeId = await AuthHelper.getEmployeeId();
      final siteID = await AuthHelper.getSiteId();
      final now = DateTime.now();
      String fmt(DateTime d) => "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

      final response = await _dioClient.dio.post(
        'attendance/byEmployee/$siteID',
        data: {
          'employeeId': employeeId,
          'fromDate': fmt(now.subtract(const Duration(days: 30))),
          'toDate': fmt(now.add(const Duration(days: 1))),
        },
      );

      final List<dynamic> raw = response.data is List ? response.data : [];
      final logs = raw.map((e) => AttendanceLog.fromJson(Map<String, dynamic>.from(e))).toList();
      add(AttendanceLogsLoaded(logs));
    } catch (e) {
      emit(state.copyWith(isLoading: false));
    }
  }

  void _scheduleMidnightRefresh(Emitter<HomeState> emit) {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
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