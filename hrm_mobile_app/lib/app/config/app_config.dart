class AppConfig {
  const AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://vpn.dptsolution.net:853/hrm/api/',
    // defaultValue: 'http://hrm.vietgoat.com:854/hrm/api/',
  );

  static const int shiftHourCompensation = int.fromEnvironment(
    'SHIFT_HOUR_COMPENSATION',
    defaultValue: 0,
  );
}
