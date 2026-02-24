class Location {
  final int id;
  final String name;
  final String? address; // Optional for flexibility
  final double latitude;
  final double longitude;
  final int radius;

  const Location({
    required this.id,
    required this.name,
    this.address,
    required this.latitude,
    required this.longitude,
    required this.radius,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Unknown',
      address: json['address'] as String?,
      latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
      radius: int.tryParse(json['radius']?.toString() ?? '100') ?? 100,
    );
  }
}