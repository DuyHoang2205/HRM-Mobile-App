class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final String? staffCode;
  final String? username;
  final String? fullName;
  final int? employeeId;
  final String? siteId;

  const LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    this.staffCode,
    this.username,
    this.fullName,
    this.employeeId,
    this.siteId,
  });

  LoginResponse copyWith({
    String? accessToken,
    String? refreshToken,
    String? staffCode,
    String? username,
    String? fullName,
    int? employeeId,
    String? siteId,
  }) {
    return LoginResponse(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      staffCode: staffCode ?? this.staffCode,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      employeeId: employeeId ?? this.employeeId,
      siteId: siteId ?? this.siteId,
    );
  }

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final employeeInfo = json['employeeInfo'] as Map<String, dynamic>?;
    final userInfo = (json['userInfo'] is Map<String, dynamic>)
        ? json['userInfo'] as Map<String, dynamic>
        : null;
    final profile = (json['profile'] is Map<String, dynamic>)
        ? json['profile'] as Map<String, dynamic>
        : null;
    final employeeIdRaw =
        json['row_id'] ??
        json['employeeId'] ??
        employeeInfo?['employeeId'] ??
        userInfo?['employeeId'] ??
        profile?['employeeId'] ??
        profile?['id'] ??
        userInfo?['EmployeeID'] ??
        json['EmployeeID'];
    final employeeId = employeeIdRaw == null
        ? null
        : int.tryParse(employeeIdRaw.toString());

    final accessToken =
        json['accessToken']?.toString() ??
        json['token']?.toString() ??
        json['jwt']?.toString() ??
        'legacy_token';

    final refreshToken =
        json['refreshToken']?.toString() ??
        json['refresh_token']?.toString() ??
        '';

    return LoginResponse(
      accessToken: accessToken,
      refreshToken: refreshToken,
      staffCode:
          json['emp_id']?.toString() ??
          employeeInfo?['staffCode']?.toString() ??
          userInfo?['staffCode']?.toString() ??
          json['staffCode']?.toString(),
      username:
          json['username']?.toString() ??
          json['no_']?.toString() ??
          json['No_']?.toString() ??
          profile?['userName']?.toString() ??
          profile?['username']?.toString() ??
          userInfo?['username']?.toString() ??
          userInfo?['UserName']?.toString(),
      fullName:
          json['fullName']?.toString() ??
          json['name']?.toString() ??
          json['Name']?.toString() ??
          json['emp_name']?.toString() ??
          profile?['name']?.toString() ??
          employeeInfo?['fullName']?.toString() ??
          userInfo?['fullName']?.toString() ??
          userInfo?['name']?.toString(),
      employeeId: employeeId,
      siteId:
          json['siteId']?.toString() ??
          json['siteID']?.toString() ??
          json['SiteID']?.toString() ??
          json['companyNo_']?.toString() ??
          json['CompanyNo_']?.toString() ??
          profile?['site']?.toString() ??
          employeeInfo?['siteId']?.toString() ??
          employeeInfo?['siteID']?.toString() ??
          userInfo?['siteId']?.toString() ??
          userInfo?['siteID']?.toString(),
    );
  }
}
