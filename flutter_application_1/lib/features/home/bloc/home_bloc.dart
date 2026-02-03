import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'home_event.dart';
import 'home_state.dart';
import '../../../core/network/dio_client.dart';


class HomeBloc extends Bloc<HomeEvent, HomeState> {
  Timer? _midnightTimer;

  HomeBloc() : super(HomeState.initial()) {
    print('HomeBloc created');
    on<HomeStarted>((event, emit) {
      // later: fetch profile / schedule / shift info
      _scheduleMidnightRefresh(emit);
    });

    on<NotificationTapped>((event, emit) {
      // later: navigate to notifications
    });

// 1. Add the DioClient to your Bloc
final DioClient _dioClient = DioClient(); 

    // 2. Inside the constructor, update the handler:
    on<CheckInTapped>((event, emit) async {
      emit(state.copyWith(isLoading: true));
      try {
        // 1. Identify current status to know if we are checking IN or OUT
        final bool isCurrentlyCheckedIn = state.isCheckedIn;

        // 2. Call the API
        await _dioClient.dio.post(
          '/attendance/insert/MOBILE_APP', 
          data: {
            'employeeID': 101, // Use the ID we put in SQL
            'location': 1,
          },
        );

        // 3. Toggle the state: If was checked in, now check out (false).
        add(CheckResultArrived(
          timestamp: DateTime.now(),
          isCheckIn: !isCurrentlyCheckedIn, 
        ));
        
      } catch (e) {
        print('Attendance API Error: $e');
      } finally {
        emit(state.copyWith(isLoading: false));
      }
    });
    
    on<CheckResultArrived>((event, emit) {
  if (event.isCheckIn) {
    emit(state.copyWith(
      checkedInAt: event.timestamp,
      checkedOutAt: null,
    ));
  } else {
    emit(state.copyWith(
      checkedOutAt: event.timestamp,
    ));
  }
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
