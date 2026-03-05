/// Model nhân viên compact — dùng cho dropdown "Giao tăng ca cho ai" (HR view).
/// Dữ liệu từ GET /employee/list-employee?site=REEME
class EmployeeItem {
  final int id; // employeeId (requestBy)
  final String fullName;
  final String? code; // staffCode

  const EmployeeItem({required this.id, required this.fullName, this.code});

  factory EmployeeItem.fromJson(Map<String, dynamic> json) {
    return EmployeeItem(
      id: (json['employeeId'] ?? json['id'] ?? json['ID'] ?? 0) is int
          ? (json['employeeId'] ?? json['id'] ?? json['ID'] ?? 0)
          : int.tryParse(
                  (json['employeeId'] ?? json['id'] ?? json['ID'] ?? '0')
                      .toString(),
                ) ??
                0,
      fullName: (json['fullName'] ?? json['FullName'] ?? json['fullname'] ?? '')
          .toString(),
      code: (json['code'] ?? json['Code'] ?? json['staffCode'])?.toString(),
    );
  }

  String get displayName =>
      code != null && code!.isNotEmpty ? '$fullName ($code)' : fullName;

  @override
  String toString() => 'EmployeeItem(id: $id, fullName: $fullName)';
}
