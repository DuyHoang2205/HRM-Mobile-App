import 'package:equatable/equatable.dart';

enum CheckInStatus { notCheckedIn, checkedIn }

class HomeState extends Equatable {
  final String initials;
  final String name;
  final String role;
  final bool isLoading;

  final DateTime today;

  // Store session
  final DateTime? checkedInAt;
  final DateTime? checkedOutAt;

  const HomeState({
    required this.initials,
    required this.name,
    required this.role,
    required this.today,
    this.isLoading = false,
    this.checkedInAt,
    this.checkedOutAt,
  });

  factory HomeState.initial() => HomeState(
        initials: 'TN',
        name: 'trung nguyen',
        role: 'Giám đốc',
        today: DateTime.now(),
      );

  bool get isCheckedIn => checkedInAt != null && checkedOutAt == null;

  // UI fields for ShiftCard (derived)
  String get shiftLabel => isCheckedIn ? 'Ra ca' : 'Vào ca';

  String get shiftTime {
    // in design: show next action time (e.g., 11:30)
    // For demo: show check-in time if already checked in, else show current time rounded (or just now)
    final t = isCheckedIn ? checkedInAt! : DateTime.now();
    return _fmtHHmm(t);
  }

  bool get isCheckoutMode => isCheckedIn;

  HomeState copyWith({
    String? initials,
    String? name,
    String? role,
    bool? isLoading,
    DateTime? today,
    DateTime? checkedInAt,
    DateTime? checkedOutAt,
  }) {
    return HomeState(
      initials: initials ?? this.initials,
      name: name ?? this.name,
      role: role ?? this.role,
      today: today ?? this.today,
      checkedInAt: checkedInAt ?? this.checkedInAt,
      checkedOutAt: checkedOutAt ?? this.checkedOutAt,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
        initials,
        name,
        role,
        today.year,
        today.month,
        today.day,
        checkedInAt?.millisecondsSinceEpoch,
        checkedOutAt?.millisecondsSinceEpoch,
        isLoading,
      ];
}

String _fmtHHmm(DateTime dt) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(dt.hour)}:${two(dt.minute)}';
}
