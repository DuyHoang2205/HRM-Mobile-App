/// Model cho dữ liệu loại phép (PermissionType) trả về từ
/// GET /api/permissionType/getAll/:siteID
///
/// Mapping với entity: src/module/permission-type/entities/permission-type.entity.ts
class PermissionTypeItem {
  final int id;
  final String permissionType;
  final String code;
  final String siteID;
  final String symbol;

  const PermissionTypeItem({
    required this.id,
    required this.permissionType,
    required this.code,
    required this.siteID,
    required this.symbol,
  });

  factory PermissionTypeItem.fromJson(Map<String, dynamic> json) {
    return PermissionTypeItem(
      id: (json['ID'] as num?)?.toInt() ?? 0,
      permissionType: json['PermissionType']?.toString() ?? '',
      code: json['Code']?.toString() ?? '',
      siteID: json['SiteID']?.toString() ?? '',
      symbol: json['Symbol']?.toString() ?? '',
    );
  }
}
