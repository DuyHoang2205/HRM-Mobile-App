import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/profile_repository.dart';
import '../../../core/auth/auth_helper.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository _repository = ProfileRepository();

  ProfileBloc() : super(const ProfileState()) {
    on<ProfileRequested>(_onProfileRequested);
  }

  Future<void> _onProfileRequested(
    ProfileRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.loading));
    try {
      final employeeId = await AuthHelper.getEmployeeId();
      final siteId = await AuthHelper.getSiteId();
      
      if (employeeId != null) {
        print('ProfileBloc: Fetching for employeeId=$employeeId, siteId=$siteId');
        final profile = await _repository.getProfile(employeeId, siteId);
        print('ProfileBloc: Fetch success. Profile exists: ${profile != null}');
        emit(state.copyWith(
          status: ProfileStatus.success,
          profile: profile,
        ));
      } else {
        emit(state.copyWith(
          status: ProfileStatus.failure,
          error: 'Không tìm thấy ID nhân viên',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: ProfileStatus.failure,
        error: e.toString(),
      ));
    }
  }
}
