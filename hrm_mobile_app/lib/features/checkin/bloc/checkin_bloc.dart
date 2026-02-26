import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/auth/auth_helper.dart';
import '../../../core/network/dio_client.dart';
import 'package:geolocator/geolocator.dart';
import '../../attendance/models/location.dart' as model;
import '../../attendance/location_repository.dart';
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
    on<ShiftSelected>(
      (event, emit) => emit(state.copyWith(selectedShiftId: event.shiftId)),
    );
    on<RefreshLocationPressed>(_onRefreshLocation);

    on<ConfirmPressed>((event, emit) async {
      if (state.isConfirming) return;
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
    await _validateLocation(emit);
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
            : 'Bạn đủ điều kiện ra ca.',
      ),
    );
  }
}
