import 'package:flutter_bloc/flutter_bloc.dart';
import 'leave_event.dart';
import 'leave_state.dart';
import '../models/leave_request.dart';

class LeaveBloc extends Bloc<LeaveEvent, LeaveState> {
  // final DioClient _dio = DioClient(); // For later

  LeaveBloc() : super(const LeaveState()) {
    on<LeaveStarted>(_onStarted);
    on<LeaveRefreshed>(_onRefreshed);
    on<LeaveRequestSubmitted>(_onSubmitted);
  }

  Future<void> _onStarted(LeaveStarted event, Emitter<LeaveState> emit) async {
    emit(state.copyWith(isLoading: true));
    await _fetchData(emit);
  }

  Future<void> _onRefreshed(LeaveRefreshed event, Emitter<LeaveState> emit) async {
    await _fetchData(emit);
  }

  Future<void> _fetchData(Emitter<LeaveState> emit) async {
    // MOCK DATA
    await Future.delayed(const Duration(milliseconds: 500));
    final mockRequests = [
      LeaveRequest(
        id: 1,
        startDate: DateTime.now().add(const Duration(days: 5)),
        endDate: DateTime.now().add(const Duration(days: 7)),
        reason: 'Nghỉ phép thường niên | Annual leave',
        location: 'Đà Lạt',
        description: 'Du lịch cùng gia đình',
        status: 'APPROVED',
        createdDate: DateTime.now().subtract(const Duration(days: 10)),
      ),
      LeaveRequest(
        id: 2,
        startDate: DateTime.now().add(const Duration(days: 20)),
        endDate: DateTime.now().add(const Duration(days: 21)),
        reason: 'Nghỉ ốm hưởng BHXH | Sick leave',
        location: 'Tại nhà',
        description: 'Sốt cao, cần nghỉ ngơi',
        status: 'PENDING',
        createdDate: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
    emit(state.copyWith(isLoading: false, requests: mockRequests));
  }

  Future<void> _onSubmitted(LeaveRequestSubmitted event, Emitter<LeaveState> emit) async {
    emit(state.copyWith(isSubmitting: true));
    
    // MOCK SUBMISSION
    await Future.delayed(const Duration(seconds: 1));
    emit(state.copyWith(isSubmitting: false, submitSuccess: 'Gửi yêu cầu thành công (MOCK)'));
    add(const LeaveRefreshed());
  }
}
