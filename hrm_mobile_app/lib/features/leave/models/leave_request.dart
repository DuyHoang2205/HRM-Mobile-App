class LeaveRequest {
  final int id;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final String? location;
  final String description;
  final String status;
  final DateTime createdDate;

  LeaveRequest({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.reason,
    this.location,
    required this.description,
    required this.status,
    required this.createdDate,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['ID'] ?? 0,
      startDate: DateTime.tryParse(json['StartDate']) ?? DateTime.now(),
      endDate: DateTime.tryParse(json['EndDate']) ?? DateTime.now(),
      reason: json['Reason'] ?? '',
      location: json['Location'],
      description: json['Description'] ?? '',
      status: json['Status'] ?? 'PENDING',
      createdDate: DateTime.tryParse(json['CreatedDate']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'StartDate': startDate.toIso8601String(),
      'EndDate': endDate.toIso8601String(),
      'Reason': reason,
      'Location': location,
      'Description': description,
    };
  }
}
