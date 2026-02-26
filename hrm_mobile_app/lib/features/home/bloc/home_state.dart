import 'package:intl/intl.dart';
import '../../attendance/models/attendance_log.dart';

class HomeState {
  final List<AttendanceLog> attendanceLogs;
  final DateTime? checkedInAt;
  final DateTime? checkedOutAt;
  final bool isLoading;
  final DateTime today;
  final String name;
  final String role;
  final String initials;

  HomeState({
    required this.attendanceLogs,
    this.checkedInAt,
    this.checkedOutAt,
    required this.isLoading,
    required this.today,
    required this.name,
    required this.role,
    required this.initials,
  });

  factory HomeState.initial() => HomeState(
        attendanceLogs: [],
        isLoading: false,
        today: DateTime.now(),
        name: "Trung Nguyen", 
        role: "Giám đốc",
        initials: "TN",
      );

  bool get isCheckoutMode => checkedInAt != null && checkedOutAt == null;

  String get shiftLabel => isCheckoutMode ? "Ra ca" : "Vào ca";

  // Updated getter to remove seconds
  String get shiftTime {
    if (isCheckoutMode && checkedInAt != null) {
      // Formats as "Vào lúc: 08:30"
      return "Vào lúc: ${DateFormat('HH:mm').format(checkedInAt!)}";
    }
    // Formats current time as "08:30" instead of "08:30:45"
    return DateFormat('HH:mm').format(DateTime.now());
  }

  HomeState copyWith({
    List<AttendanceLog>? attendanceLogs,
    DateTime? checkedInAt,
    DateTime? checkedOutAt,
    bool? isLoading,
    DateTime? today,
    String? name,
    String? role,
    String? initials,
  }) {
    return HomeState(
      attendanceLogs: attendanceLogs ?? this.attendanceLogs,
      checkedInAt: checkedInAt, 
      checkedOutAt: checkedOutAt,
      isLoading: isLoading ?? this.isLoading,
      today: today ?? this.today,
      name: name ?? this.name,
      role: role ?? this.role,
      initials: initials ?? this.initials,
    );
  }
}