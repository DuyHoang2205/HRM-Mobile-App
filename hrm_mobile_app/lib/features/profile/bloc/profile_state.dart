import '../models/user_profile.dart';

abstract class ProfileEvent {
  const ProfileEvent();
}

class ProfileRequested extends ProfileEvent {
  const ProfileRequested();
}

enum ProfileStatus { initial, loading, success, failure }

class ProfileState {
  final ProfileStatus status;
  final UserProfile? profile;
  final String? error;

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.profile,
    this.error,
  });

  ProfileState copyWith({
    ProfileStatus? status,
    UserProfile? profile,
    String? error,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      error: error ?? this.error,
    );
  }
}
