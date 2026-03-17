class DailySummary {
  final String date; // normalized yyyy-MM-dd
  final int? shiftID;
  final String? shiftCode;
  final String? shiftTitle;
  final String? shiftFromTime;
  final String? shiftToTime;
  final String? firstIn;
  final String? lastOut;
  final double? rawWorkedHours;
  final double requiredHours;
  final double? timeCalculate;
  final int? breakMinutesDeducted;
  final int lateMinutes;
  final int earlyLeaveMinutes;
  final int otEligibleMinutes;
  final int otApprovedMinutes;
  final bool? isCrossDay;
  final String? missingType;
  final double? workFraction;
  final double? leaveFraction;
  final String? leaveType;
  final String? businessTripCode;
  final String? finalizeStatus;
  final String daySymbol;

  DailySummary({
    required this.date,
    this.shiftID,
    this.shiftCode,
    this.shiftTitle,
    this.shiftFromTime,
    this.shiftToTime,
    this.firstIn,
    this.lastOut,
    this.rawWorkedHours,
    required this.requiredHours,
    this.timeCalculate,
    this.breakMinutesDeducted,
    required this.lateMinutes,
    required this.earlyLeaveMinutes,
    this.otEligibleMinutes = 0,
    this.otApprovedMinutes = 0,
    this.isCrossDay,
    this.missingType,
    this.workFraction,
    this.leaveFraction,
    this.leaveType,
    this.businessTripCode,
    this.finalizeStatus,
    required this.daySymbol,
  });

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    final rawDate =
        json['date'] ??
        json['Date'] ??
        json['workDate'] ??
        json['WorkDate'] ??
        json['day'] ??
        json['Day'];

    final rawSymbol =
        json['daySymbol'] ??
        json['DaySymbol'] ??
        json['symbol'] ??
        json['Symbol'] ??
        '0';

    return DailySummary(
      date: _normalizeDate(rawDate),
      shiftID: _toInt(
        json['shiftID'] ?? json['ShiftID'] ?? json['id'] ?? json['ID'],
      ),
      shiftCode: (json['shiftCode'] ?? json['ShiftCode'])?.toString(),
      shiftTitle:
          (json['shiftTitle'] ??
                  json['ShiftTitle'] ??
                  json['title'] ??
                  json['Title'])
              ?.toString(),
      shiftFromTime:
          (json['shiftFromTime'] ??
                  json['ShiftFromTime'] ??
                  json['fromTime'] ??
                  json['FromTime'])
              ?.toString(),
      shiftToTime:
          (json['shiftToTime'] ??
                  json['ShiftToTime'] ??
                  json['toTime'] ??
                  json['ToTime'])
              ?.toString(),
      firstIn: (json['firstIn'] ?? json['FirstIn'])?.toString(),
      lastOut: (json['lastOut'] ?? json['LastOut'])?.toString(),
      rawWorkedHours: _toDouble(
        json['rawWorkedHours'] ?? json['RawWorkedHours'],
      ),
      requiredHours:
          _toDouble(json['requiredHours'] ?? json['RequiredHours']) ?? 8.0,
      timeCalculate: _toDouble(json['timeCalculate'] ?? json['TimeCalculate']),
      breakMinutesDeducted: _toInt(
        json['breakMinutesDeducted'] ??
            json['breakMinutesDecucted'] ??
            json['BreakMinutesDeducted'] ??
            json['BreakMinutesDecucted'],
      ),
      lateMinutes: _toInt(json['lateMinutes'] ?? json['LateMinutes']) ?? 0,
      earlyLeaveMinutes:
          _toInt(json['earlyLeaveMinutes'] ?? json['EarlyLeaveMinutes']) ?? 0,
      otEligibleMinutes:
          _toInt(json['otEligibleMinutes'] ?? json['OTEligibleMinutes']) ?? 0,
      otApprovedMinutes:
          _toInt(json['otApprovedMinutes'] ?? json['OTApprovedMinutes']) ?? 0,
      isCrossDay: _toBool(json['isCrossDay'] ?? json['IsCrossDay']),
      missingType: (json['missingType'] ?? json['MissingType'])?.toString(),
      workFraction: _toDouble(json['workFraction'] ?? json['WorkFraction']),
      leaveFraction: _toDouble(json['leaveFraction'] ?? json['LeaveFraction']),
      leaveType: (json['leaveType'] ?? json['LeaveType'])?.toString(),
      businessTripCode: (json['businessTripCode'] ?? json['BusinessTripCode'])
          ?.toString(),
      finalizeStatus: (json['finalizeStatus'] ?? json['FinalizeStatus'])
          ?.toString(),
      daySymbol: rawSymbol.toString().trim().isEmpty
          ? '0'
          : rawSymbol.toString().trim(),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static bool? _toBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value.toString().trim().toLowerCase();
    if (text == 'true' || text == '1') return true;
    if (text == 'false' || text == '0') return false;
    return null;
  }

  static String _normalizeDate(dynamic value) {
    if (value == null) return '';
    final text = value.toString().trim();
    if (text.isEmpty) return '';
    try {
      final parsed = DateTime.parse(text);
      final dt = parsed.isUtc ? parsed.toLocal() : parsed;
      final y = dt.year.toString().padLeft(4, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      return '$y-$m-$d';
    } catch (_) {
      final parts = text.split('/');
      if (parts.length == 3) {
        final d = int.tryParse(parts[0]) ?? 0;
        final m = int.tryParse(parts[1]) ?? 0;
        final y = int.tryParse(parts[2]) ?? 0;
        if (y > 0 && m > 0 && d > 0) {
          return '${y.toString().padLeft(4, '0')}-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
        }
      }
      return text;
    }
  }
}
