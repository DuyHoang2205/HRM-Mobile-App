class Location {
  final int id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final int radius;
  final String? wifiName;
  final String? wifiIP;
  final String? wifiBSSID;

  const Location({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.radius,
    this.wifiName,
    this.wifiIP,
    this.wifiBSSID,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Unknown',
      address: json['address'] as String? ?? '',
      latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
      radius: int.tryParse(json['radius']?.toString() ?? '100') ?? 100,
      wifiName: json['WifiName'] as String?,
      wifiIP: json['WifiIP'] as String?,
      wifiBSSID: json['WifiBSSID'] as String?,
    );
  }
}
