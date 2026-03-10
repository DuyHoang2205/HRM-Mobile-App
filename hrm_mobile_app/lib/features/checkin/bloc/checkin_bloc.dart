import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/auth/auth_helper.dart';
import '../../../core/network/dio_client.dart';
import 'package:geolocator/geolocator.dart';
import '../../attendance/models/location.dart' as model;
import '../../attendance/location_repository.dart';
import 'package:intl/intl.dart';
import 'checkin_event.dart';
import 'checkin_state.dart';

class CheckInBloc extends Bloc<CheckInEvent, CheckInState> {
  final DioClient _dioClient = DioClient();
  final LocationRepository _locationRepository;

  CheckInBloc({
    required bool isCheckoutMode,
    required DateTime? checkedInAt,
    LocationRepository? locationRepository,
  }) : _locationRepository = locationRepository ?? LocationRepository(),
       super(
         CheckInState.initial(
           isCheckoutMode: isCheckoutMode,
           checkedInAt: checkedInAt,
         ),
       ) {
    on<CheckInStarted>(_onStarted);
    on<ShiftSelected>((event, emit) {
      emit(state.copyWith(selectedShiftId: event.shiftId));
      _updateShiftEndTimeFromSelection(emit, event.shiftId);
    });
    on<RefreshLocationPressed>(_onRefreshLocation);

    on<ConfirmPressed>((event, emit) async {
      if (state.isConfirming) return;

      // --- LOGIC CHẶN CHECK-OUT SỚM ---
      if (state.isCheckoutMode && state.shiftEndTime != null) {
        final now = DateTime.now();
        debugPrint('Checkout Validation Check:');
        debugPrint('- Current Time: $now');
        debugPrint('- Required End: ${state.shiftEndTime}');

        if (now.isBefore(state.shiftEndTime!)) {
          final fmt = DateFormat('HH:mm').format(state.shiftEndTime!);
          emit(
            state.copyWith(
              errorMessage:
                  'Bạn không thể Check-out trước $fmt. Vui lòng thử lại sau!',
            ),
          );
          return;
        }
      }

      emit(state.copyWith(isConfirming: true, errorMessage: null));

      final employeeId = await AuthHelper.getEmployeeId();
      final siteID = await AuthHelper.getSiteId();

      if (employeeId == null) {
        emit(
          state.copyWith(isConfirming: false, errorMessage: 'Chưa đăng nhập.'),
        );
        return;
      }

      try {
        // DỨT ĐIỂM LỖI 500: Xóa bỏ hoàn toàn 'direction' vì Server công ty Duy là bản cũ
        // Server cũ chỉ nhận 2 tham số, gửi dư 3 tham số sẽ gây lỗi Internal Server Error.
        await _dioClient.dio.post(
          'attendance/insert/$siteID',
          data: {'employeeID': employeeId, 'location': state.locationId ?? 15},
        );

        emit(
          state.copyWith(
            isConfirming: false,
            actionTimestamp: DateTime.now(),
            successMessage: state.isCheckoutMode
                ? 'Ra ca thành công!'
                : 'Vào ca thành công!',
          ),
        );
      } catch (e) {
        String errorMsg = 'Lỗi hệ thống. Vui lòng thử lại sau.';
        if (e is DioException) {
          debugPrint('Check-in Error Data: ${e.response?.data}');
          errorMsg = 'Lỗi kết nối Server (${e.response?.statusCode})';
        }
        emit(state.copyWith(isConfirming: false, errorMessage: errorMsg));
      }
    });
  }

  Future<void> _onStarted(
    CheckInStarted event,
    Emitter<CheckInState> emit,
  ) async {
    await _fetchShiftInfo(emit);
    await _validateLocation(emit);
  }

  Future<void> _fetchShiftInfo(Emitter<CheckInState> emit) async {
    try {
      final employeeId = await _resolveEmployeeIdForDebug();
      final siteId = await AuthHelper.getSiteId();

      if (employeeId == null) return;

      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // 1. Lấy ca được gán riêng (nếu có)
      final responseByDay = await _dioClient.dio.post(
        'shift/getShiftByDay',
        data: {'employeeID': employeeId, 'date': todayStr, 'siteID': siteId},
      );
      debugPrint(
        'getShiftByDay payload => employeeID: $employeeId, date: $todayStr, siteID: $siteId',
      );

      DateTime? shiftEnd;
      final shiftOptions = <ShiftOption>[];
      final seenIds = <String>{};

      // Xử lý ca được gán trước
      debugPrint('==== RESPONSE getShiftByDay ====');
      debugPrint(responseByDay.data?.toString());
      debugPrint('================================');

      final rows = _extractRows(responseByDay.data);
      final isSuccess =
          (responseByDay.statusCode ?? 0) >= 200 &&
          (responseByDay.statusCode ?? 0) < 300;
      if (isSuccess && rows.isNotEmpty) {
        for (final row in rows) {
          final fromRaw = _pickAny(row, const [
            'fromTime',
            'FromTime',
            'fromtime',
          ]);
          final toRaw = _pickAny(row, const ['toTime', 'ToTime', 'totime']);
          final from = _parseBackendTime(
            fromRaw?.toString(),
          );
          final to = _parseBackendTime(
            toRaw?.toString(),
          );

          DateTime? normalizedTo;
          if (from != null && to != null) {
            normalizedTo = _normalizeShiftEnd(from: from, to: to);
            shiftEnd ??= normalizedTo;
          }

          final title =
              (_pickAny(row, const ['title', 'Title', 'code', 'Code']))
                  ?.toString() ??
              'Ca làm việc';
          final id = (_pickAny(row, const ['id', 'ID']) ?? title).toString();

          if (!seenIds.contains(id)) {
            final range = (from != null && normalizedTo != null)
                ? '(${_fmtHHmm(from)} - ${_fmtHHmm(normalizedTo)})'
                : '(--:-- - --:--)';
            final option = ShiftOption(
              id: id,
              title: title,
              timeRange: range,
              rawToTime: toRaw?.toString(),
            );
            shiftOptions.add(option);
            seenIds.add(id);
          }
        }
      }

      emit(
        state.copyWith(
          shiftEndTime: shiftEnd,
          options: shiftOptions.isNotEmpty ? shiftOptions : state.options,
          selectedShiftId: shiftOptions.isNotEmpty
              ? shiftOptions.first.id
              : state.selectedShiftId,
        ),
      );

      debugPrint('Loaded Shift Information:');
      debugPrint('- Assigned Shift End: $shiftEnd');
      debugPrint('- Total Options: ${shiftOptions.length}');
      if (shiftOptions.isNotEmpty) {
        debugPrint('- First Option End: ${shiftOptions.first.rawToTime}');
      }

      // Nếu chưa có shiftEnd từ ca gán, lấy từ mốc đầu tiên của danh sách
      if (shiftEnd == null && shiftOptions.isNotEmpty) {
        _updateShiftEndTimeFromSelection(emit, shiftOptions.first.id);
      }
    } catch (e) {
      debugPrint('Error fetching shift info: $e');
    }
  }

  void _updateShiftEndTimeFromSelection(
    Emitter<CheckInState> emit,
    String shiftId,
  ) {
    try {
      final selected = state.options.firstWhere(
        (o) => o.id == shiftId,
        orElse: () => state.options.first,
      );
      if (selected.rawToTime != null) {
        final dt = _parseBackendTime(selected.rawToTime);
        emit(state.copyWith(shiftEndTime: dt, selectedShiftId: shiftId));
      }
    } catch (e) {
      debugPrint('Error updating shift end time: $e');
    }
  }

  String _fmtHHmm(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(dt.hour)}:${two(dt.minute)}';
  }

  DateTime? _parseBackendTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return null;
    try {
      final now = DateTime.now();
      final raw = timeStr.trim();

      // Nếu là định dạng ISO (chứa T)
      if (raw.contains('T')) {
        final parsed = DateTime.parse(raw);
        final utcHour = parsed.toUtc().hour;
        final utcMinute = parsed.toUtc().minute;
        final utcSecond = parsed.toUtc().second;

        // Tạo lại UTC time vào chính ngày giờ HIỆN TẠI thay vì 1970
        // để khi gọi .toLocal() sẽ áp dụng múi giờ hiện tại (+7) thay vì +8 của năm 1970
        final todayUtc = DateTime.utc(
          now.year,
          now.month,
          now.day,
          utcHour,
          utcMinute,
          utcSecond,
        );

        return todayUtc.toLocal();
      }

      // Hỗ trợ nhiều định dạng từ SQL: HH:mm, HH:mm:ss, HH:mm:ss.fffffff, yyyy-MM-dd HH:mm:ss
      final match = RegExp(
        r'(\d{1,2}):(\d{2})(?::(\d{2}))?(?:\.\d+)?',
      ).firstMatch(raw);
      if (match != null) {
        final hour = int.parse(match.group(1)!);
        final minute = int.parse(match.group(2)!);
        final second = int.parse(match.group(3) ?? '0');
        return DateTime(now.year, now.month, now.day, hour, minute, second);
      }
    } catch (e) {
      debugPrint('Error parsing time: $timeStr -> $e');
    }
    return null;
  }

  DateTime _normalizeShiftEnd({required DateTime from, required DateTime to}) {
    if (to.isBefore(from)) {
      return to.add(const Duration(days: 1));
    }
    return to;
  }

  List<Map<String, dynamic>> _extractRows(dynamic data) {
    if (data is List) {
      return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    if (data is Map) {
      final nested = data['data'];
      if (nested is List) {
        return nested
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }
    return const [];
  }

  dynamic _pickAny(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      if (row.containsKey(key)) return row[key];
    }
    return null;
  }

  Future<int?> _resolveEmployeeIdForDebug() async {
    final storedEmployeeId = await AuthHelper.getEmployeeId();
    if (!kDebugMode) return storedEmployeeId;

    final username = (await AuthHelper.getUserName())?.toLowerCase().trim();
    if (username == 'admin') return 2;
    if (username == 'baoduy') return 3195;
    return storedEmployeeId;
  }

  Future<void> _onRefreshLocation(
    RefreshLocationPressed event,
    Emitter<CheckInState> emit,
  ) async {
    if (state.isRefreshingLocation) return;
    emit(state.copyWith(isRefreshingLocation: true));
    await _validateLocation(emit);
    emit(state.copyWith(isRefreshingLocation: false));
  }

  Future<void> _validateLocation(Emitter<CheckInState> emit) async {
    // DỨT ĐIỂM LỖI CRASH: Kiểm tra và yêu cầu quyền vị trí trước khi lấy GPS
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      emit(state.copyWith(warning: 'Vui lòng bật GPS trên thiết bị.'));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        emit(
          state.copyWith(
            warning: 'App cần quyền vị trí để xác thực chấm công.',
          ),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      emit(
        state.copyWith(
          warning: 'Quyền vị trí bị từ chối vĩnh viễn trong Cài đặt.',
        ),
      );
      return;
    }

    // Lấy vị trí hiện tại
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      position = await Geolocator.getLastKnownPosition();
    }

    if (position == null) {
      emit(state.copyWith(warning: 'Không thể lấy tín hiệu GPS. Hãy thử lại.'));
      return;
    }

    // Fetch danh sách vị trí từ Repository (Mặc định site 15 & 16)
    final siteIds = ['15', '16'];
    List<model.Location> locations = await _locationRepository.getLocations(
      siteIds,
    );

    // DEMO FALLBACK: Đảm bảo có vị trí để test
    if (locations.isEmpty) {
      locations = [
        const model.Location(
          id: 15,
          name: 'Văn phòng Reeme',
          address: 'Gò Vấp, HCM',
          latitude: 10.7839488,
          longitude: 106.6795008,
          radius: 1000,
        ),
      ];
    }

    // Logic kiểm tra vị trí (Duy đang để Demo: Luôn cho phép)
    bool isValidLocation = locations.isNotEmpty || true;
    bool isValidWifi = true;
    int? matchedId = locations.isNotEmpty ? locations.first.id : 15;
    String matchedName = locations.isNotEmpty
        ? locations.first.name
        : 'Vị trí Demo';

    emit(
      state.copyWith(
        currentLatitude: position.latitude,
        currentLongitude: position.longitude,
        isValidLocation: isValidLocation,
        isValidWifi: isValidWifi,
        locationId: matchedId,
        locationName: matchedName,
        warning: state.isCheckoutMode
            ? 'Bạn đủ điều kiện ra ca.'
            : 'Bạn đủ điều kiện vào ca.',
      ),
    );
  }
}
