import 'package:equatable/equatable.dart';

class ShiftOption extends Equatable {
  final String id;
  final String title;
  final String timeRange;
  final String? rawToTime;

  const ShiftOption({
    required this.id,
    required this.title,
    required this.timeRange,
    this.rawToTime,
  });

  @override
  List<Object?> get props => [id, title, timeRange, rawToTime];
}

class WordReasonOption extends Equatable {
  final String code;
  final String name;

  const WordReasonOption({
    required this.code,
    required this.name,
  });

  @override
  List<Object?> get props => [code, name];
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

  final List<WordReasonOption> wordReasons;

  final bool isRefreshingLocation;
  final bool isConfirming;

  final bool isValidLocation;
  final bool isValidWifi;
  final int? locationId;
  final String locationName;
  final double? currentLatitude;
  final double? currentLongitude;

  // NEW: success flow
  final String? successMessage;
  final String? errorMessage;
  final String? earlyCheckoutWarningMessage;
  final DateTime? actionTimestamp;

  // NEW: early check-out validation
  final DateTime? shiftEndTime;

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
    required this.wordReasons,
    required this.isRefreshingLocation,
    required this.isConfirming,
    required this.isValidLocation,
    required this.isValidWifi,
    required this.locationId,
    required this.locationName,
    required this.currentLatitude,
    required this.currentLongitude,
    required this.successMessage,
    required this.errorMessage,
    required this.earlyCheckoutWarningMessage,
    required this.actionTimestamp,
    required this.shiftEndTime,
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
        ShiftOption(id: 'personal', title: 'Ca Cá Nhân', timeRange: range),
      ],
      selectedShiftId: 'personal',
      wordReasons: const [],
      isRefreshingLocation: false,
      isConfirming: false,
      isValidLocation: false,
      isValidWifi: false,
      locationId: null,
      locationName: 'Unknown',
      currentLatitude: null,
      currentLongitude: null,
      successMessage: null,
      errorMessage: null,
      earlyCheckoutWarningMessage: null,
      actionTimestamp: null,
      shiftEndTime: null,
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
    List<WordReasonOption>? wordReasons,
    bool? isRefreshingLocation,
    bool? isConfirming,
    bool? isValidLocation,
    bool? isValidWifi,
    int? locationId,
    String? locationName,
    double? currentLatitude,
    double? currentLongitude,
    String? successMessage,
    String? errorMessage,
    String? earlyCheckoutWarningMessage,
    DateTime? actionTimestamp,
    DateTime? shiftEndTime,
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
      wordReasons: wordReasons ?? this.wordReasons,
      isRefreshingLocation: isRefreshingLocation ?? this.isRefreshingLocation,
      isConfirming: isConfirming ?? this.isConfirming,
      isValidLocation: isValidLocation ?? this.isValidLocation,
      isValidWifi: isValidWifi ?? this.isValidWifi,
      locationId: locationId ?? this.locationId,
      locationName: locationName ?? this.locationName,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      successMessage: successMessage,
      errorMessage: errorMessage,
      earlyCheckoutWarningMessage: earlyCheckoutWarningMessage,
      actionTimestamp: actionTimestamp ?? this.actionTimestamp,
      shiftEndTime: shiftEndTime ?? this.shiftEndTime,
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
    wordReasons,
    isRefreshingLocation,
    isConfirming,
    isValidLocation,
    isValidWifi,
    locationId,
    locationName,
    currentLatitude,
    currentLongitude,
    successMessage,
    errorMessage,
    earlyCheckoutWarningMessage,
    actionTimestamp?.millisecondsSinceEpoch,
    shiftEndTime?.millisecondsSinceEpoch,
  ];
}

String _fmtHHmm(DateTime dt) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(dt.hour)}:${two(dt.minute)}';
}
