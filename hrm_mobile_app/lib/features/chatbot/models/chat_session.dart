import 'package:equatable/equatable.dart';

class ChatSession extends Equatable {
  final String id;
  final String userNo;
  final int? employeeId;
  final String state;
  final String? escalationReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ChatSession({
    required this.id,
    required this.userNo,
    required this.employeeId,
    required this.state,
    this.escalationReason,
    this.createdAt,
    this.updatedAt,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id']?.toString() ?? '',
      userNo: json['user_no']?.toString() ?? '',
      employeeId: json['employee_id'] is num
          ? (json['employee_id'] as num).toInt()
          : int.tryParse('${json['employee_id']}'),
      state: json['state']?.toString() ?? 'active',
      escalationReason: json['escalation_reason']?.toString(),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  @override
  List<Object?> get props => [
        id,
        userNo,
        employeeId,
        state,
        escalationReason,
        createdAt,
        updatedAt,
      ];
}
