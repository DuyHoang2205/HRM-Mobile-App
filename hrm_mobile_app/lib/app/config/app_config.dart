class AppConfig {
  const AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://erp.vietgoat.com:854/hrm/api/',
    // defaultValue: 'http://192.168.1.5:3004/api/', // Local development IP
  );

  static const int shiftHourCompensation = int.fromEnvironment(
    'SHIFT_HOUR_COMPENSATION',
    defaultValue: 0,
  );
}
