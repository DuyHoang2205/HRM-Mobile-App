import 'package:equatable/equatable.dart';
import '../models/overtime_request.dart';

abstract class OvertimeEvent extends Equatable {
  const OvertimeEvent();
  @override
  List<Object?> get props => [];
}

/// Tải danh sách tăng ca lần đầu
class OvertimeStarted extends OvertimeEvent {
  const OvertimeStarted();
}

/// Pull-to-refresh
class OvertimeRefreshed extends OvertimeEvent {
  const OvertimeRefreshed();
}

/// Nộp đơn tăng ca mới
class OvertimeRequestSubmitted extends OvertimeEvent {
  final OvertimeRequest request;
  const OvertimeRequestSubmitted(this.request);
  @override
  List<Object?> get props => [request];
}
