import 'package:equatable/equatable.dart';
import '../../../core/utils/attendance_time_parser.dart';

enum AttendanceAction { checkIn, checkOut }

class AttendanceLog extends Equatable {
  final int id;
  final String userName;
  final String subtitle;
  final DateTime timestamp;
  final AttendanceAction action;

  const AttendanceLog({
    required this.id,
    required this.userName,
    required this.subtitle,
    required this.timestamp,
    required this.action,
  });

  factory AttendanceLog.fromJson(Map<String, dynamic> json) {
    // 1. Parse ID safely
    final id = json['id'] is int
        ? json['id']
        : int.tryParse(json['id']?.toString() ?? '0') ?? 0;

    // 2. Define rawAuthDate properly to avoid 'Undefined name' error
    final dynamic rawAuthDate = json['authDate'];
    
    if (rawAuthDate == null) {
      throw Exception('Missing authDate');
    }
    
    // 3. Use the parser (passing both date and time)
    final timestamp = AttendanceTimeParser.parseDateTime(
      date: rawAuthDate,
      time: json['authTime'],
    );

    final code = json['attendCode'] ?? '';

    return AttendanceLog(
      id: id,
      userName: 'Nhân viên $code',
      subtitle: 'Vào/Ra ca trên điện thoại',
      timestamp: timestamp,
      action: AttendanceAction.checkIn, // Default; resolved by AttendanceActionResolver
    );
  }

  AttendanceLog copyWith({AttendanceAction? action}) {
    return AttendanceLog(
      id: id,
      userName: userName,
      subtitle: subtitle,
      timestamp: timestamp,
      action: action ?? this.action,
    );
  }

  @override
  List<Object?> get props => [id, userName, subtitle, timestamp, action];
}