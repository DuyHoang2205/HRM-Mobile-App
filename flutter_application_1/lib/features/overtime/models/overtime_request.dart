class OvertimeRequest {
  final int id;
  final DateTime date;
  final String startTime;
  final String endTime;
  final bool isNextDay;
  final String reason;
  final String description;
  final String status;
  final DateTime createdDate;

  OvertimeRequest({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.isNextDay,
    required this.reason,
    required this.description,
    required this.status,
    required this.createdDate,
  });

  factory OvertimeRequest.fromJson(Map<String, dynamic> json) {
    return OvertimeRequest(
      id: json['ID'] ?? 0,
      date: DateTime.tryParse(json['Date']) ?? DateTime.now(),
      startTime: json['StartTime'] ?? '',
      endTime: json['EndTime'] ?? '',
      isNextDay: json['IsNextDay'] ?? false,
      reason: json['Reason'] ?? '',
      description: json['Description'] ?? '',
      status: json['Status'] ?? 'PENDING',
      createdDate: DateTime.tryParse(json['CreatedDate']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Date': date.toIso8601String(),
      'StartTime': startTime,
      'EndTime': endTime,
      'IsNextDay': isNextDay,
      'Reason': reason,
      'Description': description,
    };
  }
}
