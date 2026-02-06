import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/auth/auth_helper.dart';
import 'overtime_event.dart';
import 'overtime_state.dart';
import '../models/overtime_request.dart';

class OvertimeBloc extends Bloc<OvertimeEvent, OvertimeState> {
  final DioClient _dio = DioClient();

  OvertimeBloc() : super(const OvertimeState()) {
    on<OvertimeStarted>(_onStarted);
    on<OvertimeRefreshed>(_onRefreshed);
    on<OvertimeRequestSubmitted>(_onSubmitted);
  }

  Future<void> _onStarted(OvertimeStarted event, Emitter<OvertimeState> emit) async {
    emit(state.copyWith(isLoading: true));
    await _fetchData(emit);
  }

  Future<void> _onRefreshed(OvertimeRefreshed event, Emitter<OvertimeState> emit) async {
    // refresh without setting isLoading true if you prefer, or set it true.
    // Usually pull-to-refresh handles spinner.
    await _fetchData(emit);
  }

  Future<void> _fetchData(Emitter<OvertimeState> emit) async {
    // MOCK DATA FOR UI TESTING
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate net
    final mockRequests = [
      OvertimeRequest(
        id: 1,
        date: DateTime.now(),
        startTime: '17:30',
        endTime: '19:30',
        isNextDay: false,
        reason: 'Tăng ca chạy Deadline',
        description: 'Fix bug gấp server',
        status: 'APPROVED',
        createdDate: DateTime.now().subtract(const Duration(days: 1)),
      ),
      OvertimeRequest(
         id: 2,
        date: DateTime.now().add(const Duration(days: 1)),
        startTime: '18:00',
        endTime: '20:00',
        isNextDay: false,
        reason: 'Lý do khác | Other',
        description: 'Họp team',
        status: 'PENDING',
        createdDate: DateTime.now(),
      ),
    ];
     emit(state.copyWith(isLoading: false, requests: mockRequests));

    /* API INTEGRATION PENDING BACKEND
    try {
      final siteId = await AuthHelper.getSiteId();
      final employeeId = await AuthHelper.getEmployeeId();

      if (siteId == null || employeeId == null) {
        emit(state.copyWith(isLoading: false, error: 'Authentication Error'));
        return;
      }

      final response = await _dio.dio.get(
        'overtime-request/$siteId',
        queryParameters: {'employeeId': employeeId},
      );

      final List<dynamic> raw = response.data is List ? response.data as List : [];
      final requests = raw.map((e) => OvertimeRequest.fromJson(e)).toList();

      emit(state.copyWith(isLoading: false, requests: requests));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
    */
  }

  Future<void> _onSubmitted(OvertimeRequestSubmitted event, Emitter<OvertimeState> emit) async {
    emit(state.copyWith(isSubmitting: true));
    
    // MOCK SUBMISSION
    await Future.delayed(const Duration(seconds: 1));
    emit(state.copyWith(isSubmitting: false, submitSuccess: 'Gửi yêu cầu thành công (MOCK)'));
    // In real app, we would add the new item to the list or refresh.
    // For mock, we can just trigger a refresh which will reload the mock list.
    add(const OvertimeRefreshed());

    /* API INTEGRATION PENDING BACKEND
    try {
      final siteId = await AuthHelper.getSiteId();
      final employeeId = await AuthHelper.getEmployeeId();

      if (siteId == null || employeeId == null) throw Exception('Auth missing');

      final body = event.request.toJson();
      body['SiteID'] = siteId;
      body['EmployeeID'] = int.tryParse(employeeId) ?? 0;

      await _dio.dio.post('overtime-request', data: body);

      emit(state.copyWith(isSubmitting: false, submitSuccess: 'Gửi yêu cầu thành công'));
      // Refresh list
      add(const OvertimeRefreshed());
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, error: e.toString()));
    }
    */
  }
}
