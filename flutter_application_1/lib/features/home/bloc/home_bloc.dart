import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'home_event.dart';
import 'home_state.dart';

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

    // on<CheckInTapped>((event, emit) {
    //   // simple local state update for check-in; backend integration later
    //   emit(state.copyWith(checkInStatus: CheckInStatus.checkedIn));
    // });
    
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
