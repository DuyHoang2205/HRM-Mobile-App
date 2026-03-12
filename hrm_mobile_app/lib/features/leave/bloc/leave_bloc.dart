import 'package:flutter_bloc/flutter_bloc.dart';
import 'leave_event.dart';
import 'leave_state.dart';
import '../data/leave_repository.dart';
import '../../../core/auth/auth_helper.dart';

class LeaveBloc extends Bloc<LeaveEvent, LeaveState> {
  final LeaveRepository _repository;
  final bool businessTripMode;

  LeaveBloc({LeaveRepository? repository, this.businessTripMode = false})
    : _repository = repository ?? LeaveRepository(),
      super(const LeaveState()) {
    on<LeaveStarted>(_onStarted);
    on<LeaveRefreshed>(_onRefreshed);
    on<LeaveRequestSubmitted>(_onSubmitted);
  }

  Future<void> _onStarted(LeaveStarted event, Emitter<LeaveState> emit) async {
    emit(state.copyWith(isLoading: true));
    await _fetchData(emit);
  }

  Future<void> _onRefreshed(
    LeaveRefreshed event,
    Emitter<LeaveState> emit,
  ) async {
    await _fetchData(emit);
  }

  Future<void> _fetchData(Emitter<LeaveState> emit) async {
    try {
      // Lấy thông tin user từ session (không hardcode)
      final employeeId = await AuthHelper.getEmployeeId();
      final siteId = await AuthHelper.getSiteId();
      final now = DateTime.now();

      if (employeeId == null) {
        emit(
          state.copyWith(
            isLoading: false,
            error:
                'Không lấy được thông tin nhân viên. Vui lòng đăng nhập lại.',
          ),
        );
        return;
      }

      // Gọi 2 API song song để tối ưu tốc độ, type-safe
      final requestsFuture = businessTripMode
          ? _repository.getBusinessTripRequests(
              employeeID: employeeId,
              year: now.year,
              siteID: siteId,
            )
          : _repository.getLeaveRequests(
              employeeID: employeeId,
              year: now.year,
              siteID: siteId,
            );
      final permissionTypesFuture = _repository.getPermissionTypes(siteId);

      final requests = await requestsFuture;
      final permissionTypes = await permissionTypesFuture;

      emit(
        state.copyWith(
          isLoading: false,
          requests: requests,
          permissionTypes: permissionTypes,
          error: null,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onSubmitted(
    LeaveRequestSubmitted event,
    Emitter<LeaveState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true, errorMessage: null));
    try {
      if (businessTripMode) {
        await _repository.submitBusinessTripRequest(event.request.toJson());
      } else {
        await _repository.submitLeaveRequest(event.request.toJson());
      }
      emit(
        state.copyWith(
          isSubmitting: false,
          submitSuccess: 'Gửi yêu cầu thành công',
        ),
      );
      add(const LeaveRefreshed());
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, errorMessage: e.toString()));
    }
  }
}
