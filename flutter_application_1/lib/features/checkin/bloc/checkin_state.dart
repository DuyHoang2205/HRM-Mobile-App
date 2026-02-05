import 'package:equatable/equatable.dart';

class ShiftOption extends Equatable {
  final String id;
  final String title;
  final String timeRange;

  const ShiftOption({
    required this.id,
    required this.title,
    required this.timeRange,
  });

  @override
  List<Object?> get props => [id, title, timeRange];
}

class CheckInState extends Equatable {
  final String initials;

  final String wifiName;
  final String bssid;
  final String wifiLabelRight;

  final bool isCheckoutMode;
  final DateTime? checkedInAt;

  final String warning;

  final List<ShiftOption> options;
  final String? selectedShiftId;

  final bool isRefreshingLocation;
  final bool isConfirming;

  // Success / error from API
  final String? successMessage;
  final String? errorMessage;
  final DateTime? actionTimestamp;

  const CheckInState({
    required this.initials,
    required this.wifiName,
    required this.bssid,
    required this.wifiLabelRight,
    required this.isCheckoutMode,
    required this.checkedInAt,
    required this.warning,
    required this.options,
    required this.selectedShiftId,
    required this.isRefreshingLocation,
    required this.isConfirming,
    required this.successMessage,
    required this.errorMessage,
    required this.actionTimestamp,
  });

  factory CheckInState.initial({
    required bool isCheckoutMode,
    required DateTime? checkedInAt,
  }) {
    final now = DateTime.now();
    final start = checkedInAt ?? now;
    final range = isCheckoutMode
        ? '(${_fmtHHmm(start)} - ${_fmtHHmm(now)})'
        : '(${_fmtHHmm(now)} - ${_fmtHHmm(now)})';

    return CheckInState(
      initials: 'TN', // TODO BACKEND
      wifiName: 'wifi', // TODO BACKEND
      bssid: 'a0:9:2c:7c:7c:cc', // TODO BACKEND
      wifiLabelRight: 'DPT', // TODO BACKEND
      isCheckoutMode: isCheckoutMode,
      checkedInAt: checkedInAt,
      warning: isCheckoutMode
          ? 'Bạn đang trong ca làm. Xác nhận để ra ca.'
          : 'Hiện tại bạn chưa có Ca làm. Bạn có muốn tiếp tục vào ca cá nhân?',
      options: [
        ShiftOption(
          id: 'personal',
          title: 'Ca Cá Nhân',
          timeRange: range,
        ),
      ],
      selectedShiftId: 'personal',
      isRefreshingLocation: false,
      isConfirming: false,
      successMessage: null,
      errorMessage: null,
      actionTimestamp: null,
    );
  }

  CheckInState copyWith({
    String? initials,
    String? wifiName,
    String? bssid,
    String? wifiLabelRight,
    bool? isCheckoutMode,
    DateTime? checkedInAt,
    String? warning,
    List<ShiftOption>? options,
    String? selectedShiftId,
    bool? isRefreshingLocation,
    bool? isConfirming,
    String? successMessage,
    String? errorMessage,
    DateTime? actionTimestamp,
  }) {
    return CheckInState(
      initials: initials ?? this.initials,
      wifiName: wifiName ?? this.wifiName,
      bssid: bssid ?? this.bssid,
      wifiLabelRight: wifiLabelRight ?? this.wifiLabelRight,
      isCheckoutMode: isCheckoutMode ?? this.isCheckoutMode,
      checkedInAt: checkedInAt ?? this.checkedInAt,
      warning: warning ?? this.warning,
      options: options ?? this.options,
      selectedShiftId: selectedShiftId ?? this.selectedShiftId,
      isRefreshingLocation: isRefreshingLocation ?? this.isRefreshingLocation,
      isConfirming: isConfirming ?? this.isConfirming,
      successMessage: successMessage,
      errorMessage: errorMessage,
      actionTimestamp: actionTimestamp ?? this.actionTimestamp,
    );
  }

  @override
  List<Object?> get props => [
        initials,
        wifiName,
        bssid,
        wifiLabelRight,
        isCheckoutMode,
        checkedInAt?.millisecondsSinceEpoch,
        warning,
        options,
        selectedShiftId,
        isRefreshingLocation,
        isConfirming,
        successMessage,
        errorMessage,
        actionTimestamp?.millisecondsSinceEpoch,
      ];
}

String _fmtHHmm(DateTime dt) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(dt.hour)}:${two(dt.minute)}';
}
