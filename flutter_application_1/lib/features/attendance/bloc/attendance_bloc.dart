import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/demo/demo_attendance_store.dart';
import 'attendance_event.dart';
import 'attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  AttendanceBloc() : super(AttendanceState.initial()) {
    on<AttendanceStarted>((event, emit) {
      emit(state.copyWith(logs: List.unmodifiable(DemoAttendanceStore.logs)));
    });
  }
}
