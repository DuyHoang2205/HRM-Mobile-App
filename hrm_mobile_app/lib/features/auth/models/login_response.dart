class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final String? staffCode;

  const LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    this.staffCode,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final employeeInfo = json['employeeInfo'] as Map<String, dynamic>?;
    return LoginResponse(
      accessToken: json['accessToken']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
      staffCode: employeeInfo?['staffCode']?.toString(),
    );
  }
}
