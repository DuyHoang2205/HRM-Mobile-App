import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../../app/config/app_config.dart';
import 'attendance_event.dart';
import 'attendance_state.dart';
import '../models/attendance_log.dart';
import '../models/daily_summary.dart';
import '../../../core/utils/attendance_action_resolver.dart';
import '../../../core/utils/attendance_day_policy.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/auth/auth_helper.dart';
import '../../leave/data/leave_repository.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  static const int _shiftServerHourCompensation =
      AppConfig.shiftHourCompensation;
  final DioClient _dioClient = DioClient();

  AttendanceBloc() : super(AttendanceState.initial()) {
    on<AttendanceStarted>(_onLoad);
    on<AttendanceRefreshed>(_onLoad);
    on<AttendanceFilterChanged>(_onFilterChanged);
    on<AttendanceTimesheetDateChanged>(_onTimesheetDateChanged);
    on<AttendanceCheckResultArrived>(_onLoad);
    on<AttendanceChangeSubmitted>(_onSubmitChange);
  }

  Future<void> _onSubmitChange(
    AttendanceChangeSubmitted event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(
      state.copyWith(
        isSubmittingChange: true,
        error: '',
        changeSuccessMessage: '',
      ),
    );
    try {
      final employeeId = await AuthHelper.getEmployeeId();
      final siteID = await AuthHelper.getSiteId();
      final createdBy = await AuthHelper.getStaffCode() ?? 'admin';

      final String timeString = "${event.date}T${event.time}";
      final response = await _submitAttendanceChange(
        employeeId: employeeId,
        siteID: siteID,
        createdBy: createdBy,
        date: event.date,
        timeString: timeString,
        shiftID: event.shiftID,
        reason: event.reason,
        note: event.note,
        attachmentPaths: event.attachmentPaths,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        emit(
          state.copyWith(
            isSubmittingChange: false,
            changeSuccessMessage: 'Đã gửi giải trình thành công',
          ),
        );
      } else {
        emit(
          state.copyWith(
            isSubmittingChange: false,
            error: 'Gửi thất bại, vui lòng thử lại',
          ),
        );
      }
    } catch (e) {
      _debug("Submit change error: $e");
      emit(
        state.copyWith(
          isSubmittingChange: false,
          error: 'Lỗi khi gửi giải trình: $e',
        ),
      );
    }
  }

  Future<Response<dynamic>> _submitAttendanceChange({
    required int? employeeId,
    required String siteID,
    required String createdBy,
    required String date,
    required String timeString,
    required int shiftID,
    required String reason,
    required String note,
    required List<String> attachmentPaths,
  }) async {
    final responseOffset = await _dioClient.dio.post(
      'timekeepingOffset',
      data: {
        'employeeID': employeeId,
        'status': 0,
        'dateApply': date,
        'shiftID': shiftID,
        'reason': reason,
        'note': note,
        'fromTime': timeString,
        'toTime': timeString,
        'requestBy': employeeId,
        'createBy': createdBy,
        'updateBy': createdBy,
        'siteID': siteID,
      },
    );

    final cleanedPaths = attachmentPaths
        .where((path) => path.trim().isNotEmpty)
        .toList();

    if (cleanedPaths.isEmpty) {
      return responseOffset;
    }

    final files = <MultipartFile>[];
    for (final path in cleanedPaths) {
      final file = File(path);
      if (!file.existsSync()) continue;
      files.add(
        await MultipartFile.fromFile(path, filename: _fileNameFromPath(path)),
      );
    }

    final formData = FormData.fromMap({
      "employeeID": employeeId,
      "authDate": date,
      "authTime": timeString,
      "createdBy": createdBy,
      "siteID": siteID,
      "reason": reason,
      // `files` is the standard key expected by most NestJS upload interceptors.
      "files": files,
    });

    await _dioClient.dio.post('attendance/change/$siteID', data: formData);
    return responseOffset;
  }

  String _fileNameFromPath(String path) {
    final normalized = path.replaceAll('\\', '/');
    final segments = normalized.split('/');
    return segments.isEmpty ? path : segments.last;
  }

  Future<void> _onTimesheetDateChanged(
    AttendanceTimesheetDateChanged event,
    Emitter<AttendanceState> emit,
  ) async {
    try {
      final employeeId = await AuthHelper.getEmployeeId();
      final siteID = await AuthHelper.getSiteId();

      String fmt(DateTime d) =>
          "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

      final summaryResponse = await _fetchDailySummary(
        siteID: siteID,
        employeeId: employeeId,
        fromDate: fmt(event.start),
        toDate: fmt(event.end),
        month: event.start.month,
        year: event.start.year,
      );

      final raw = summaryResponse.data;
      final List<dynamic> list = raw is List
          ? raw
          : (raw is Map && raw['data'] is List)
          ? (raw['data'] as List)
          : const [];

      final newMap = Map<String, DailySummary>.from(state.dailySummaries);
      for (var item in list) {
        if (item is! Map) continue;
        final summary = DailySummary.fromJson(Map<String, dynamic>.from(item));
        if (summary.date.isEmpty) continue;
        newMap[summary.date] = summary;
      }

      await _overlayLeaves(newMap, employeeId ?? 0, event.start.year, siteID);

      emit(state.copyWith(dailySummaries: newMap));
    } catch (_) {}
  }

  Future<void> _onFilterChanged(
    AttendanceFilterChanged event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(
      state.copyWith(
        filterDate: event.start,
        endDate: event.end,
        isLoading: true,
      ),
    );
    await _fetchLogs(emit);
  }

  Future<void> _onLoad(
    AttendanceEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    await _fetchLogs(emit);
  }

  Future<void> _fetchLogs(Emitter<AttendanceState> emit) async {
    emit(state.copyWith(isLoading: true));

    try {
      final employeeId = await AuthHelper.getEmployeeId();
      final siteID = await AuthHelper.getSiteId();
      final fullName = await AuthHelper.getFullName() ?? 'Trung Nguyen';

      final start = state.filterDate;
      // queryEnd is inclusive for filtering
      final DateTime queryEnd = state.endDate ?? DateTime.now();

      String fmt(DateTime d) =>
          "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

      List<AttendanceLog> allLogs = [];
      Map<String, DailySummary> summariesMap = {};

      // 1. Fetch Daily Summaries for Timesheet UI (NEW API)
      try {
        final fFromDate = fmt(start);
        final fToDate = fmt(queryEnd);
        final summaryResponse = await _fetchDailySummary(
          siteID: siteID,
          employeeId: employeeId,
          fromDate: fFromDate,
          toDate: fToDate,
          month: start.month,
          year: start.year,
        );

        final raw = summaryResponse.data;
        final List<dynamic> list = raw is List
            ? raw
            : (raw is Map && raw['data'] is List)
            ? (raw['data'] as List)
            : const [];

        _debug('[DailySummary] list length = ${list.length}');
        for (var item in list) {
          if (item is! Map) continue;
          final summary = DailySummary.fromJson(
            Map<String, dynamic>.from(item),
          );
          if (summary.date.isEmpty) continue;
          summariesMap[summary.date] = summary;
          _debug(
            '[DailySummary] loaded key=${summary.date} symbol=${summary.daySymbol}',
          );
        }
        _debug('[DailySummary] total keys = ${summariesMap.keys.length}');

        await _overlayLeaves(summariesMap, employeeId ?? 0, start.year, siteID);
      } catch (e, st) {
        _debug('Failed to fetch daily summaries: $e\n$st');
      }

      // 2. Fetch Raw Attendance Logs for Timeline UI (Existing logic)
      final daysDiff = queryEnd.difference(start).inDays;

      try {
        final fFromDate = fmt(start);
        final fToDate = fmt(queryEnd);

        final response = await _dioClient.dio.post(
          'attendance/byEmployee/$siteID',
          data: {
            'employeeId': employeeId,
            'fromDate': fFromDate,
            'toDate': fToDate,
          },
        );

        if (response.data is List) {
          final list = response.data as List;
          if (list.isNotEmpty) {
            allLogs = list
                .map(
                  (e) => AttendanceLog.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList();
          }
        }
      } catch (e) {
        _debug('byEmployee fallback to getScanByDay due to error: $e');
      }

      if (allLogs.isEmpty) {
        _debug('byEmployee returned empty, using getScanByDay loop fallback');
        List<Future<Response>> futures = [];
        for (int i = 0; i <= daysDiff; i++) {
          final date = start.add(Duration(days: i));
          futures.add(
            _dioClient.dio.post(
              'attendance/getScanByDay/$siteID',
              data: {'employeeID': employeeId, 'day': fmt(date)},
            ),
          );
        }

        final responses = await Future.wait(futures);
        for (final response in responses) {
          try {
            if (response.data is List) {
              final list = response.data as List;
              allLogs.addAll(
                list.map(
                  (e) => AttendanceLog.fromJson(Map<String, dynamic>.from(e)),
                ),
              );
            }
          } catch (e) {
            // ignore
          }
        }
      }

      final uniqueLogs = <AttendanceLog>[];
      for (var log in allLogs) {
        uniqueLogs.add(log);
      }
      allLogs = uniqueLogs;

      if (summariesMap.isEmpty) {
        summariesMap = await _buildSummariesFromScans(
          employeeId: employeeId ?? 0,
          siteID: siteID,
          start: start,
          end: queryEnd,
          logs: allLogs,
        );
        await _overlayLeaves(summariesMap, employeeId ?? 0, start.year, siteID);
        _debug(
          '[DailySummary] fallback from scans total keys = ${summariesMap.keys.length}',
        );
      }

      // Sort by timestamp desc
      allLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      final resolved = AttendanceActionResolver.resolve(allLogs);
      final finalLogs = resolved
          .map((log) => log.copyWith(userName: fullName))
          .toList();

      // Keep fetching dayPolicies for now if anything else depends on it
      final dayPolicies = await _fetchDayPolicies(
        employeeId: employeeId ?? 0,
        siteID: siteID,
        start: start,
        end: queryEnd,
      );

      emit(
        state.copyWith(
          logs: finalLogs,
          dayPolicies: dayPolicies,
          dailySummaries: summariesMap,
          isLoading: false,
          error: null,
        ),
      );
    } catch (e, s) {
      // Never let loading hang
      _debug('Attendance fetch error: $e');
      _debug(s.toString());

      emit(
        state.copyWith(
          isLoading: false,
          error: 'Không thể tải dữ liệu. Vui lòng thử lại.',
        ),
      );
    }
  }

  Future<Map<String, AttendancePolicyConfig>> _fetchDayPolicies({
    required int employeeId,
    required String siteID,
    required DateTime start,
    required DateTime end,
  }) async {
    if (employeeId <= 0) return const {};

    final result = <String, AttendancePolicyConfig>{};
    final days = end.difference(start).inDays;

    for (int i = 0; i <= days; i++) {
      final day = start.add(Duration(days: i));
      final dayStr =
          "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
      try {
        final response = await _dioClient.dio.post(
          'shift/getShiftByDay',
          data: {'employeeID': employeeId, 'date': dayStr, 'siteID': siteID},
        );
        final ok =
            (response.statusCode ?? 0) >= 200 &&
            (response.statusCode ?? 0) < 300;
        if (!ok || response.data is! List) continue;
        final rows = response.data as List;
        if (rows.isEmpty) continue;

        final row = Map<String, dynamic>.from(rows.first as Map);
        final minFromWorkTime = _durationFromHourDecimal(
          _toDouble(row['timeCalculate']) > 0
              ? _toDouble(row['timeCalculate'])
              : _toDouble(row['workTime']),
        );
        if (minFromWorkTime == null) continue;

        final breaks = <WorkBreakWindow>[];
        final breakStart = _parseBackendTime(
          (row['startBreak'] ?? row['StartBreak'])?.toString(),
        );
        final breakEnd = _parseBackendTime(
          (row['endBreak'] ?? row['EndBreak'])?.toString(),
        );
        if (breakStart != null && breakEnd != null) {
          breaks.add(
            WorkBreakWindow(
              startHour: breakStart.hour,
              startMinute: breakStart.minute,
              endHour: breakEnd.hour,
              endMinute: breakEnd.minute,
            ),
          );
        }

        result[dayStr] = AttendancePolicyConfig(
          minimumWorkDuration: minFromWorkTime,
          breakWindows: breaks,
        );
      } catch (_) {
        // ignore day-level policy fetch error, keep other dates working
      }
    }
    return result;
  }

  Future<Map<String, DailySummary>> _buildSummariesFromScans({
    required int employeeId,
    required String siteID,
    required DateTime start,
    required DateTime end,
    required List<AttendanceLog> logs,
  }) async {
    final result = <String, DailySummary>{};
    if (employeeId <= 0) return result;

    final logsByDate = <String, List<AttendanceLog>>{};
    for (final log in logs) {
      final key = _fmtDate(log.timestamp);
      (logsByDate[key] ??= <AttendanceLog>[]).add(log);
    }

    final days = end.difference(start).inDays;
    for (int i = 0; i <= days; i++) {
      final day = DateTime(start.year, start.month, start.day + i);
      final dayStr = _fmtDate(day);
      final shiftRow = await _fetchShiftRow(
        employeeId: employeeId,
        siteID: siteID,
        dayStr: dayStr,
      );

      final dayLogs = (logsByDate[dayStr] ?? <AttendanceLog>[])
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      final firstLog = dayLogs.isNotEmpty ? dayLogs.first.timestamp : null;
      final lastLog = dayLogs.isNotEmpty ? dayLogs.last.timestamp : null;

      final shiftTitle = shiftRow == null
          ? null
          : (_pickAny(shiftRow, const ['title', 'Title']))?.toString();
      final shiftCode = shiftRow == null
          ? null
          : (_pickAny(shiftRow, const ['code', 'Code', 'title', 'Title']))
                ?.toString();
      final shiftId = shiftRow == null
          ? null
          : _toInt(_pickAny(shiftRow, const ['id', 'ID']));
      final from = shiftRow == null
          ? null
          : _parseBackendTime(
              _pickAny(shiftRow, const ['fromTime', 'FromTime'])?.toString(),
            );
      final to = shiftRow == null
          ? null
          : _parseBackendTime(
              _pickAny(shiftRow, const ['toTime', 'ToTime'])?.toString(),
            );
      final breakStart = shiftRow == null
          ? null
          : _parseBackendTime(
              _pickAny(
                shiftRow,
                const ['startBreak', 'StartBreak'],
              )?.toString(),
            );
      final breakEnd = shiftRow == null
          ? null
          : _parseBackendTime(
              _pickAny(shiftRow, const ['endBreak', 'EndBreak'])?.toString(),
            );
      final isCrossDay = shiftRow == null
          ? null
          : _toInt(_pickAny(shiftRow, const ['isCrossDay', 'IsCrossDay'])) == 1;

      final workedMinutes = _calculateWorkedMinutes(
        firstLog: firstLog,
        lastLog: lastLog,
        breakStart: breakStart,
        breakEnd: breakEnd,
      );
      final breakMinutes = _calculateBreakMinutes(
        firstLog: firstLog,
        lastLog: lastLog,
        breakStart: breakStart,
        breakEnd: breakEnd,
      );
      final timeCalculate =
          shiftRow == null
              ? null
              : ((_pickAny(
                          shiftRow,
                          const ['timeCalculate', 'TimeCalculate'],
                        ) !=
                        null)
                    ? _toDouble(
                        _pickAny(
                          shiftRow,
                          const ['timeCalculate', 'TimeCalculate'],
                        ),
                      )
                    : _toDouble(
                        _pickAny(shiftRow, const ['workTime', 'WorkTime']),
                      ));
      final requiredHours =
          shiftRow == null
              ? 8.0
              : _toDouble(_pickAny(shiftRow, const ['workTime', 'WorkTime']));

      final lateMinutes =
          (from != null && firstLog != null && firstLog.isAfter(from))
              ? firstLog.difference(from).inMinutes
              : 0;
      final earlyLeaveMinutes =
          (to != null &&
                  lastLog != null &&
                  (isCrossDay != true) &&
                  lastLog.isBefore(to))
              ? to.difference(lastLog).inMinutes
              : 0;

      final rawWorkedHours =
          firstLog == null || lastLog == null ? null : workedMinutes / 60.0;

      final symbol =
          firstLog == null || lastLog == null
              ? '0'
              : ((timeCalculate ?? requiredHours) > 0 &&
                        rawWorkedHours != null &&
                        rawWorkedHours >= (timeCalculate ?? requiredHours))
              ? '1'
              : 'x/P';

      result[dayStr] = DailySummary(
        date: dayStr,
        shiftID: shiftId,
        shiftCode: shiftCode,
        shiftTitle: shiftTitle,
        shiftFromTime: from == null ? null : _fmtHHmmss(from),
        shiftToTime: to == null ? null : _fmtHHmmss(to),
        firstIn: firstLog == null ? null : _fmtHHmmss(firstLog),
        lastOut: lastLog == null ? null : _fmtHHmmss(lastLog),
        rawWorkedHours: rawWorkedHours == null
            ? null
            : double.parse(rawWorkedHours.toStringAsFixed(2)),
        requiredHours: requiredHours,
        timeCalculate: timeCalculate,
        breakMinutesDeducted: breakMinutes,
        lateMinutes: lateMinutes,
        earlyLeaveMinutes: earlyLeaveMinutes,
        isCrossDay: isCrossDay,
        daySymbol: symbol,
      );
    }

    return result;
  }

  Future<Map<String, dynamic>?> _fetchShiftRow({
    required int employeeId,
    required String siteID,
    required String dayStr,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        'shift/getShiftByDay',
        data: {'employeeID': employeeId, 'date': dayStr, 'siteID': siteID},
      );
      final ok =
          (response.statusCode ?? 0) >= 200 &&
          (response.statusCode ?? 0) < 300;
      if (!ok || response.data is! List) return null;
      final rows = response.data as List;
      if (rows.isEmpty || rows.first is! Map) return null;
      return Map<String, dynamic>.from(rows.first as Map);
    } catch (_) {
      return null;
    }
  }

  int _calculateWorkedMinutes({
    required DateTime? firstLog,
    required DateTime? lastLog,
    required DateTime? breakStart,
    required DateTime? breakEnd,
  }) {
    if (firstLog == null || lastLog == null) return 0;
    final raw = lastLog.difference(firstLog).inMinutes;
    return raw - _calculateBreakMinutes(
      firstLog: firstLog,
      lastLog: lastLog,
      breakStart: breakStart,
      breakEnd: breakEnd,
    );
  }

  int _calculateBreakMinutes({
    required DateTime? firstLog,
    required DateTime? lastLog,
    required DateTime? breakStart,
    required DateTime? breakEnd,
  }) {
    if (firstLog == null ||
        lastLog == null ||
        breakStart == null ||
        breakEnd == null) {
      return 0;
    }
    if (!firstLog.isBefore(breakEnd) || !lastLog.isAfter(breakStart)) {
      return 0;
    }

    final overlapStart = firstLog.isAfter(breakStart) ? firstLog : breakStart;
    final overlapEnd = lastLog.isBefore(breakEnd) ? lastLog : breakEnd;
    if (!overlapEnd.isAfter(overlapStart)) return 0;
    return overlapEnd.difference(overlapStart).inMinutes;
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  Duration? _durationFromHourDecimal(double hourValue) {
    if (hourValue <= 0) return null;
    final minutes = (hourValue * 60).round();
    return Duration(minutes: minutes);
  }

  DateTime? _parseBackendTime(String? timeStr) {
    if (timeStr == null || timeStr.trim().isEmpty) return null;
    final raw = timeStr.trim();
    final now = DateTime.now();
    try {
      if (raw.contains('T')) {
        final parsed = DateTime.parse(raw);
        final utcHour = parsed.toUtc().hour;
        final utcMinute = parsed.toUtc().minute;
        final utcSecond = parsed.toUtc().second;
        final todayUtc = DateTime.utc(
          now.year,
          now.month,
          now.day,
          utcHour,
          utcMinute,
          utcSecond,
        );
        return todayUtc.toLocal().add(
          const Duration(hours: _shiftServerHourCompensation),
        );
      }

      final match = RegExp(
        r'(\d{1,2}):(\d{2})(?::(\d{2}))?(?:\.\d+)?',
      ).firstMatch(raw);
      if (match == null) return null;

      final hour = int.parse(match.group(1)!);
      final minute = int.parse(match.group(2)!);
      final second = int.parse(match.group(3) ?? '0');
      return DateTime(now.year, now.month, now.day, hour, minute, second);
    } catch (_) {
      return null;
    }
  }

  String _fmtDate(DateTime value) =>
      "${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}";

  String _fmtHHmmss(DateTime value) =>
      "${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}:${value.second.toString().padLeft(2, '0')}";

  dynamic _pickAny(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      if (row.containsKey(key) && row[key] != null) return row[key];
    }
    return null;
  }

  Future<Response<dynamic>> _fetchDailySummary({
    required String siteID,
    required int? employeeId,
    required String fromDate,
    required String toDate,
    required int month,
    required int year,
  }) async {
    final payload = {
      'employeeId': employeeId,
      'fromDate': fromDate,
      'toDate': toDate,
    };

    try {
      // Primary route in current backend:
      // POST /attendance/summary/:siteID (AttendanceController.getDailySummary)
      return await _dioClient.dio.post(
        'attendance/summary/$siteID',
        data: payload,
      );
    } catch (_) {
      // Backward compatibility for older environments.
      return _dioClient.dio.post(
        'attendance/mobile/daily-summary/$siteID',
        data: {
          ...payload,
          'employeeID': employeeId,
          'month': month,
          'year': year,
        },
      );
    }
  }

  void _debug(String message) {
    if (!kDebugMode) return;
    debugPrint(message);
  }

  Future<void> _overlayLeaves(
    Map<String, DailySummary> map,
    int employeeId,
    int year,
    String siteID,
  ) async {
    try {
      final leaveRepo = LeaveRepository();
      final leaves = await leaveRepo.getLeaveRequests(
        employeeID: employeeId,
        year: year,
        siteID: siteID,
      );
      final permissionTypes = await leaveRepo.getPermissionTypes(siteID);
      final symbolByPermissionId = <int, String>{
        for (final p in permissionTypes) p.id: p.symbol.trim().toUpperCase(),
      };

      final approvedLeaves = leaves.where((l) => l.status == 3).toList();
      _debug('[Overlay] ${approvedLeaves.length} approved leaves to overlay');
      for (var leave in approvedLeaves) {
        DateTime current = DateTime(
          leave.fromDate.year,
          leave.fromDate.month,
          leave.fromDate.day,
        );
        final end = DateTime(
          leave.toDate.year,
          leave.toDate.month,
          leave.toDate.day,
        );
        final isMultiDay =
            leave.fromDate.year != leave.toDate.year ||
            leave.fromDate.month != leave.toDate.month ||
            leave.fromDate.day != leave.toDate.day;
        final leaveSymbol =
            symbolByPermissionId[leave.permissionType]?.trim().toUpperCase() ??
            'P';
        final isBusinessTrip = leaveSymbol == 'C';
        final isFullDayLeave = isMultiDay || leave.qty >= 1;

        while (current.compareTo(end) <= 0) {
          final dateStr =
              "${current.year}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')}";
          final existing = map[dateStr];

          final existingSymbol = existing?.daySymbol.trim().toUpperCase() ?? '';
          final isMissingOrEmpty =
              existing == null ||
              existingSymbol.isEmpty ||
              existingSymbol == '0' ||
              existingSymbol == 'X';

          if (isBusinessTrip) {
            // Business trip always has highest display priority on timesheet.
            map[dateStr] = DailySummary(
              date: dateStr,
              daySymbol: 'C',
              requiredHours: existing?.requiredHours ?? 8.0,
              lateMinutes: 0,
              earlyLeaveMinutes: 0,
              shiftCode: existing?.shiftCode,
              shiftTitle: existing?.shiftTitle,
              shiftFromTime: existing?.shiftFromTime,
              shiftToTime: existing?.shiftToTime,
              firstIn: existing?.firstIn,
              lastOut: existing?.lastOut,
              rawWorkedHours: existing?.rawWorkedHours,
              breakMinutesDeducted: existing?.breakMinutesDeducted,
              timeCalculate: existing?.timeCalculate,
              otEligibleMinutes: existing?.otEligibleMinutes ?? 0,
              otApprovedMinutes: existing?.otApprovedMinutes ?? 0,
              isCrossDay: existing?.isCrossDay,
              missingType: existing?.missingType,
              workFraction: existing?.workFraction,
              leaveFraction: leave.qty,
              leaveType: leave.description,
              businessTripCode:
                  existing?.businessTripCode ?? leave.permissionType.toString(),
              finalizeStatus: existing?.finalizeStatus,
            );
            _debug(
              '[Overlay] Force C on $dateStr (prev: ${existing?.daySymbol})',
            );
          } else if (isFullDayLeave) {
            // Full-day leave has highest priority.
            map[dateStr] = DailySummary(
              date: dateStr,
              daySymbol: 'P',
              requiredHours: 8.0,
              lateMinutes: 0,
              earlyLeaveMinutes: 0,
              shiftCode: existing?.shiftCode,
              shiftTitle: existing?.shiftTitle,
              shiftFromTime: existing?.shiftFromTime,
              shiftToTime: existing?.shiftToTime,
              leaveType: leave.description,
            );
            _debug(
              '[Overlay] Force P on $dateStr (prev: ${existing?.daySymbol})',
            );
          } else if (isMissingOrEmpty) {
            // Half-day leave on empty/missing day -> mark as leave.
            map[dateStr] = DailySummary(
              date: dateStr,
              daySymbol: 'P',
              requiredHours: 8.0,
              lateMinutes: 0,
              earlyLeaveMinutes: 0,
              shiftCode: existing?.shiftCode,
              shiftTitle: existing?.shiftTitle,
              shiftFromTime: existing?.shiftFromTime,
              shiftToTime: existing?.shiftToTime,
              leaveType: leave.description,
            );
            _debug(
              '[Overlay] Add P on $dateStr (prev: ${existing?.daySymbol})',
            );
          } else {
            // Half-day leave + existing attendance -> x/P
            map[dateStr] = DailySummary(
              date: dateStr,
              daySymbol: 'x/P',
              requiredHours: existing.requiredHours,
              lateMinutes: existing.lateMinutes,
              earlyLeaveMinutes: existing.earlyLeaveMinutes,
              shiftCode: existing.shiftCode,
              shiftTitle: existing.shiftTitle,
              shiftFromTime: existing.shiftFromTime,
              shiftToTime: existing.shiftToTime,
              firstIn: existing.firstIn,
              lastOut: existing.lastOut,
              rawWorkedHours: existing.rawWorkedHours,
              breakMinutesDeducted: existing.breakMinutesDeducted,
              timeCalculate: existing.timeCalculate,
              otEligibleMinutes: existing.otEligibleMinutes,
              otApprovedMinutes: existing.otApprovedMinutes,
              isCrossDay: existing.isCrossDay,
              missingType: existing.missingType,
              workFraction: existing.workFraction,
              leaveFraction: leave.qty,
              leaveType: leave.description,
              businessTripCode: existing.businessTripCode,
              finalizeStatus: existing.finalizeStatus,
            );
            _debug('[Overlay] Merge half-day leave -> x/P on $dateStr');
          }
          current = current.add(const Duration(days: 1));
        }
      }
    } catch (e, st) {
      _debug('Overlay leave error: $e\n$st');
    }
  }
}
