import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/auth/auth_helper.dart';
import '../../../core/helpers/permission_helper.dart';
import '../data/overtime_repository.dart';
import '../models/attendance_record.dart';
import '../models/employee_item.dart';
import '../models/leave_record.dart';
import '../models/overtime_request.dart';
import '../models/shift_item.dart';
import 'overtime_event.dart';
import 'overtime_state.dart';

class OvertimeBloc extends Bloc<OvertimeEvent, OvertimeState> {
  final OvertimeRepository _repository;

  OvertimeBloc({OvertimeRepository? repository})
    : _repository = repository ?? OvertimeRepository(),
      super(const OvertimeState()) {
    on<OvertimeStarted>(_onStarted);
    on<OvertimeRefreshed>(_onRefreshed);
    on<OvertimeRequestSubmitted>(_onSubmitted);
  }

  Future<void> _onStarted(
    OvertimeStarted event,
    Emitter<OvertimeState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    await _fetchData(emit);
  }

  Future<void> _onRefreshed(
    OvertimeRefreshed event,
    Emitter<OvertimeState> emit,
  ) async {
    await _fetchData(emit);
  }

  Future<void> _fetchData(Emitter<OvertimeState> emit) async {
    try {
      final siteId = await AuthHelper.getSiteId();
      final employeeId = await AuthHelper.getEmployeeId() ?? 0;
      final now = DateTime.now();
      // Lấy dữ liệu từ đầu năm đến cuối năm
      final yearStart = DateTime(now.year, 1, 1);
      final yearEnd = DateTime(now.year, 12, 31);

      // Check quyền frmOvertime/Add
      final bool isHR = await PermissionHelper.canAddOvertime();

      // Fetch dữ liệu song song
      final shiftsFuture = _repository.getOvertimeShifts(siteId);

      final requestsFuture = _repository.getOvertimeRequests(
        year: now.year,
        siteID: siteId,
        employeeId: isHR ? 0 : employeeId,
      );

      // HR load danh sách nhân viên; Employee load leave+attendance của mình
      final employeesFuture = isHR
          ? _repository.getEmployeeList(siteId)
          : Future.value(<EmployeeItem>[]);

      final leavesFuture = !isHR && employeeId > 0
          ? _repository.getLeavesByEmployee(
              siteID: siteId,
              employeeId: employeeId,
            )
          : Future.value(<LeaveRecord>[]);

      final attendanceFuture = !isHR && employeeId > 0
          ? _repository.getAttendanceByEmployee(
              siteID: siteId,
              employeeId: employeeId,
              fromDate: yearStart,
              toDate: yearEnd,
            )
          : Future.value(<AttendanceRecord>[]);

      // Await tất cả
      final List<ShiftItem> shifts = await shiftsFuture;
      final List<OvertimeRequest> requests = await requestsFuture;
      final List<EmployeeItem> employees = await employeesFuture;
      final List<LeaveRecord> leaves = isHR
          ? await _getLeavesForRequests(siteId, requests)
          : await leavesFuture;
      final List<AttendanceRecord> attendance = await attendanceFuture;

      emit(
        state.copyWith(
          isLoading: false,
          isHR: isHR,
          requests: requests,
          shifts: shifts,
          employees: employees,
          leaves: leaves,
          attendance: attendance,
          error: null,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<List<LeaveRecord>> _getLeavesForRequests(
    String siteId,
    List<OvertimeRequest> requests,
  ) async {
    final employeeIds = requests
        .map((r) => r.requestBy)
        .where((id) => id > 0)
        .toSet()
        .toList();

    if (employeeIds.isEmpty) return <LeaveRecord>[];

    final leavesByEmployee = await Future.wait(
      employeeIds.map(
        (id) async =>
            _repository.getLeavesByEmployee(siteID: siteId, employeeId: id),
      ),
    );

    return leavesByEmployee.expand((items) => items).toList();
  }

  Future<void> _onSubmitted(
    OvertimeRequestSubmitted event,
    Emitter<OvertimeState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true, errorMessage: null));
    try {
      await _repository.submitOvertimeRequest(event.request);
      emit(
        state.copyWith(
          isSubmitting: false,
          submitSuccess: state.isHR
              ? 'Đã tạo phiếu tăng ca'
              : 'Gửi yêu cầu thành công',
        ),
      );
      add(const OvertimeRefreshed());
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, errorMessage: e.toString()));
    }
  }
}
