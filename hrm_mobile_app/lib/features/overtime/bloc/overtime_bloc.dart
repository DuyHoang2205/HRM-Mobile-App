import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/overtime_repository.dart';
import '../models/overtime_model.dart';
import 'overtime_event.dart';
import 'overtime_state.dart';

class OvertimeBloc extends Bloc<OvertimeEvent, OvertimeState> {
  final OvertimeRepository _repository;

  OvertimeBloc({required OvertimeRepository repository})
    : _repository = repository,
      super(const OvertimeState()) {
    on<LoadOvertimeList>(_onLoadOvertimeList);
    on<SubmitOvertimeRequest>(_onSubmitOvertimeRequest);
  }

  Future<void> _onLoadOvertimeList(
    LoadOvertimeList event,
    Emitter<OvertimeState> emit,
  ) async {
    emit(state.copyWith(status: OvertimeStatus.loading));
    try {
      final requests = await _repository.fetchOvertimeRequests();
      emit(state.copyWith(status: OvertimeStatus.success, requests: requests));
    } catch (e) {
      emit(
        state.copyWith(
          status: OvertimeStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onSubmitOvertimeRequest(
    SubmitOvertimeRequest event,
    Emitter<OvertimeState> emit,
  ) async {
    emit(state.copyWith(status: OvertimeStatus.submitting));
    try {
      // Calculate basic total hours for mock logic
      final startParts = event.startTime.split(':');
      final endParts = event.endTime.split(':');
      double totalHrs = 0;
      if (startParts.length == 2 && endParts.length == 2) {
        final startMin =
            int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
        int endMin = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
        if (event.isNextDay) endMin += 24 * 60;
        totalHrs = (endMin - startMin) / 60.0;
        if (totalHrs < 0) totalHrs = 0;
      }

      final newRequest = OvertimeModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: event.date,
        startTime: event.startTime,
        endTime: event.endTime,
        totalHours: double.parse(totalHrs.toStringAsFixed(1)),
        reason: event.reason,
        description: event.description,
        isNextDay: event.isNextDay,
        breakMinutes: event.breakMinutes,
        reeproDispatch: event.reeproDispatch,
        reeproProject: event.reeproProject,
        approverName: 'Phạm Văn D', // Hardcoded approver
        status: 'Chờ duyệt',
      );

      await _repository.createOvertimeRequest(newRequest);

      // Emit success and refresh the list
      emit(state.copyWith(status: OvertimeStatus.submitSuccess));
      add(const LoadOvertimeList());
    } catch (e) {
      emit(
        state.copyWith(
          status: OvertimeStatus.submitFailure,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
