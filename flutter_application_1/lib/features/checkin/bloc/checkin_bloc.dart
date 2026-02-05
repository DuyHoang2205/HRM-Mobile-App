import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/auth/auth_helper.dart';
import '../../../core/network/dio_client.dart';
import 'checkin_event.dart';
import 'checkin_state.dart';

class CheckInBloc extends Bloc<CheckInEvent, CheckInState> {
  final DioClient _dioClient = DioClient();

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

    on<ConfirmPressed>(_onConfirmPressed);

    on<PrivacyPressed>((event, emit) {});
  }

  Future<void> _onConfirmPressed(ConfirmPressed event, Emitter<CheckInState> emit) async {
    if (state.isConfirming) return;
    emit(state.copyWith(isConfirming: true, errorMessage: null));

    final employeeId = await AuthHelper.getEmployeeId();
    if (employeeId == null) {
      emit(state.copyWith(
        isConfirming: false,
        errorMessage: 'Chưa đăng nhập hoặc không có thông tin nhân viên.',
      ));
      return;
    }

    final siteID = await AuthHelper.getSiteId();
    try {
      await _dioClient.dio.post(
        '/attendance/insert/$siteID',
        data: {
          'employeeID': employeeId,
          'location': 1,
        },
      );
      final now = DateTime.now();
      emit(state.copyWith(
        isConfirming: false,
        actionTimestamp: now,
        successMessage: state.isCheckoutMode ? 'Ra ca thành công!' : 'Vào ca thành công!',
      ));
    } catch (e) {
      final message = e.toString().replaceFirst('DioException [unknown]: ', '');
      emit(state.copyWith(
        isConfirming: false,
        errorMessage: message.isNotEmpty ? message : 'Có lỗi xảy ra. Vui lòng thử lại.',
      ));
    }
  }
}
