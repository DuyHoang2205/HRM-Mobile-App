import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'checkin_event.dart';
import 'checkin_state.dart';

class CheckInBloc extends Bloc<CheckInEvent, CheckInState> {
  CheckInBloc({
    required bool isCheckoutMode,
    required DateTime? checkedInAt,
  }) : super(CheckInState.initial(isCheckoutMode: isCheckoutMode, checkedInAt: checkedInAt)) {
    on<CheckInStarted>((event, emit) {});

    on<ShiftSelected>((event, emit) {
      emit(state.copyWith(selectedShiftId: event.shiftId));
    });

    on<RefreshLocationPressed>((event, emit) async {
      if (state.isRefreshingLocation) return;
      emit(state.copyWith(isRefreshingLocation: true));
      await Future<void>.delayed(const Duration(milliseconds: 600));
      emit(state.copyWith(isRefreshingLocation: false));
    });

    on<ConfirmPressed>((event, emit) async {
      if (state.isConfirming) return;
      emit(state.copyWith(isConfirming: true));

      final now = DateTime.now();

      // TODO BACKEND later: call API, receive server timestamp + session info
      await Future<void>.delayed(const Duration(milliseconds: 400));

      emit(state.copyWith(
        isConfirming: false,
        actionTimestamp: now,
        successMessage: state.isCheckoutMode ? 'Ra ca thành công!' : 'Vào ca thành công!',
      ));
    });

    on<PrivacyPressed>((event, emit) {});
  }
}
