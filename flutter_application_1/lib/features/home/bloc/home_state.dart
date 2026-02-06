import 'package:equatable/equatable.dart';
import '../../attendance/models/attendance_log.dart';

class HomeState extends Equatable {
  final DateTime today;
  final List<AttendanceLog> attendanceLogs;
  final DateTime? checkedInAt;
  final DateTime? checkedOutAt;
  final bool isLoading;
  final String name;
  final String initials;
  final String role;

  const HomeState({
    required this.today,
    required this.attendanceLogs,
    this.checkedInAt,
    this.checkedOutAt,
    this.isLoading = false,
    this.name = 'Duy Hoang',
    this.initials = 'DH',
    this.role = 'Software Engineer',
  });

  factory HomeState.initial() => HomeState(today: DateTime.now(), attendanceLogs: const []);

  // Card is RED (Ra ca) only if we have a check-in and haven't checked out yet
  bool get isCheckoutMode => checkedInAt != null && checkedOutAt == null;

  String get shiftLabel => isCheckoutMode ? 'Ra ca' : 'Vào ca';

  String get shiftTime {
    if (isCheckoutMode && checkedInAt != null) {
      return 'Đã vào: ${_fmtTime(checkedInAt!)}';
    }
    return 'Giờ hiện tại: ${_fmtTime(DateTime.now())}';
  }

  static String _fmtTime(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  HomeState copyWith({
    DateTime? today,
    List<AttendanceLog>? attendanceLogs,
    DateTime? checkedInAt,
    DateTime? checkedOutAt,
    bool? isLoading,
    String? name,
    String? initials,
    String? role,
  }) {
    return HomeState(
      today: today ?? this.today,
      attendanceLogs: attendanceLogs ?? this.attendanceLogs,
      checkedInAt: checkedInAt, // Direct assignment allows nulls
      checkedOutAt: checkedOutAt,
      isLoading: isLoading ?? this.isLoading,
      name: name ?? this.name,
      initials: initials ?? this.initials,
      role: role ?? this.role,
    );
  }

  @override
  List<Object?> get props => [today, attendanceLogs, checkedInAt, checkedOutAt, isLoading, name, initials, role];
}