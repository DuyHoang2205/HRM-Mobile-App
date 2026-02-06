import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/auth/auth_helper.dart';
import '../../../core/network/dio_client.dart';
import 'package:geolocator/geolocator.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
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
  })  : _locationRepository = locationRepository ?? LocationRepository(),
        super(CheckInState.initial(isCheckoutMode: isCheckoutMode, checkedInAt: checkedInAt)) {
    print('DEBUG CheckInBloc: Init with isCheckoutMode=$isCheckoutMode');
    on<CheckInStarted>(_onStarted);

    on<ShiftSelected>((event, emit) {
      emit(state.copyWith(selectedShiftId: event.shiftId));
    });

    on<RefreshLocationPressed>(_onRefreshLocation);

    on<ConfirmPressed>((event, emit) async {
      if (state.isConfirming) return;
      emit(state.copyWith(isConfirming: true, errorMessage: null));

      final employeeId = await AuthHelper.getEmployeeId();
      if (employeeId == null) {
        emit(state.copyWith(
          isConfirming: false,
          errorMessage: 'Chưa đăng nhập hoặc không có thông tin nhân viên.',
        ));
        return;
      }

      final siteID = await AuthHelper.getSiteId();
      try {
        await _dioClient.dio.post(
          'attendance/insert/$siteID',
          data: {
            'employeeID': employeeId,
            'location': state.locationId ?? 0,
          },
        );
        final now = DateTime.now();

        // TODO BACKEND later: call API, receive server timestamp + session info
        await Future<void>.delayed(const Duration(milliseconds: 400));

        emit(state.copyWith(
          isConfirming: false,
          actionTimestamp: now,
          successMessage: state.isCheckoutMode ? 'Ra ca thành công!' : 'Vào ca thành công!',
        ));
      } catch (e) {
        final message = e.toString().replaceFirst('DioException [unknown]: ', '');
        emit(state.copyWith(
          isConfirming: false,
          errorMessage: message.isNotEmpty ? message : 'Có lỗi xảy ra. Vui lòng thử lại.',
        ));
      }
    });

    on<PrivacyPressed>((event, emit) {});
  }

  Future<void> _onStarted(CheckInStarted event, Emitter<CheckInState> emit) async {
    await _validateLocation(emit);
  }

  Future<void> _onRefreshLocation(RefreshLocationPressed event, Emitter<CheckInState> emit) async {
    if (state.isRefreshingLocation) return;
    emit(state.copyWith(isRefreshingLocation: true));
    await _validateLocation(emit);
    emit(state.copyWith(isRefreshingLocation: false));
  }

  Future<void> _validateLocation(Emitter<CheckInState> emit) async {
    print('Starting Validation... State isCheckoutMode=${state.isCheckoutMode}');
    // 1. Permissions (Using Geolocator directly)
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        emit(state.copyWith(warning: 'Bạn đã từ chối quyền vị trí.'));
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      emit(state.copyWith(warning: 'Quyền vị trí bị chặn vĩnh viễn. Hãy mở Cài đặt để cấp quyền.'));
      return;
    }

    // 2. Get Current Location
    Position? position;
    try {
      // Add a timeout to prevent infinite hanging
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5), 
      );
      print('Got Position: ${position.latitude}, ${position.longitude}');
    } on TimeoutException {
      // If native location takes too long (common on Simulator)
      // Try to get last known position as fallback
      position = await Geolocator.getLastKnownPosition();
      if (position != null) {
        print('Got Last Known Position: ${position.latitude}, ${position.longitude}');
      } else {
         print('Location Timeout and no last known position');
         emit(state.copyWith(warning: 'Không thể lấy vị trí (Timeout). Hãy kiểm tra GPS/Simulator.'));
         return;
      }
    } catch (e) {
      print('Geolocator Error: $e');
      // Check if service is disabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
         emit(state.copyWith(warning: 'Dịch vụ vị trí bị tắt. Hãy bật GPS.'));
      } else {
         emit(state.copyWith(warning: 'Lỗi lấy vị trí: $e'));
      }
      return;
    }

    // 3. Get Current WiFi (Optional - just to check if connected)
    // WiFi validation is disabled - only location matters for check-in
    // final info = NetworkInfo();
    // String? wifiName;
    // String? wifiBSSID;
    // try {
    //    wifiName = await info.getWifiName();
    // } catch (e) {
    //    print('Error getting Wifi info: $e');
    // }
    
    String? wifiName = 'Not checked';
    String? wifiBSSID;

    // 4. Fetch Locations for Multiple Sites
    // Hardcoded supported sites for now as per plan
    final siteIds = ['REEME', 'MEREE']; 
    final locations = await _locationRepository.getLocations(siteIds);
    print('Got ${locations.length} locations across sites: $siteIds');

    // 5. Validation Loop
    bool isValidLocation = false;
    bool isValidWifi = false;
    int? matchedId;
    String matchedName = 'Unknown Area';
    
    // Check against all locations
    for (final loc in locations) {
      // Check Distance
      final dist = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        loc.latitude, // Ensure these are parsed as doubles in Model
        loc.longitude,
      );
      
      // STRICT 100m Radius Rule
      // Use location's radius if defined, else default to 100m, but capped/min at 100m logic if desired.
      // Logic: If within radius, Location is VALID.
      double effectiveRadius = loc.radius > 0 ? loc.radius.toDouble() : 100.0;
      
      print('Checking ${loc.name} (${loc.id}): Dist=${dist.toStringAsFixed(2)}m vs Radius=$effectiveRadius');
      
      if (dist <= effectiveRadius) {
        matchedName = loc.name;
        isValidLocation = true;
        matchedId = loc.id;
        
        // WiFi validation disabled - only location matters
        // Users just need to be on WiFi (any WiFi) to use the app
        isValidWifi = true;
        break; // Location matched, that's all we need
      }
    }

    // 6. Final Decision Logic
    // Only location matters - WiFi validation is disabled
    String warning = '';
    
    if (!isValidLocation) {
      warning = 'Bạn đang không ở trong khu vực chấm công (quá 100m).';
    } else {
      // Valid location = can check in
      warning = state.isCheckoutMode ? 'Bạn có thể ra ca.' : 'Bạn có thể vào ca.';
    }

    emit(state.copyWith(
      currentLatitude: position.latitude,
      currentLongitude: position.longitude,
      wifiName: wifiName,
      bssid: wifiBSSID ?? 'Unknown',
      isValidLocation: isValidLocation,
      isValidWifi: isValidWifi, // UI can use this to show Yellow/Green icon
      locationId: matchedId,
      locationName: matchedName,
      warning: warning,
    ));
  }
}
