enum AttendanceAction { checkIn, checkOut } // Add this line

class AttendanceLog {
  final int id;
  final String userName;
  final String subtitle;
  final DateTime timestamp;
  final AttendanceAction action;

  AttendanceLog({
    required this.id,
    required this.userName,
    required this.subtitle,
    required this.timestamp,
    required this.action,
  });

  factory AttendanceLog.fromJson(Map<String, dynamic> json) {
    // 1. Parse ID
    final id = json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0;

    // 2. Parse Timestamp (AuthDate + AuthTime)
    // Expecting AuthDate to be YYYY-MM-DDT... or similar
    // Expecting AuthTime to be HH:mm:ss or similar
    final authDateStr = (json['authDate'] ?? json['AuthDate'])?.toString();
    final authTimeStr = (json['authTime'] ?? json['AuthTime'])?.toString();

    DateTime timestamp = DateTime.now();

    if (authDateStr != null) {
      final datePart = DateTime.tryParse(authDateStr);
      if (datePart != null) {
        timestamp = datePart; // Start with the date
        if (authTimeStr != null) {
          // If we have a time string, try to parse it and add to the date
          try {
             // Handle "1900-01-01T08:00:00" or "08:00:00"
             // If it's ISO, DateTime.parse works. If it's just time, we need to parse manually if needed.
             // But usually API returns full datetime string for Time columns in some SQL drivers, or just HH:mm:ss
             if (authTimeStr.contains('T')) {
                 final timePart = DateTime.parse(authTimeStr);
                 timestamp = DateTime(
                   timestamp.year, timestamp.month, timestamp.day,
                   timePart.hour, timePart.minute, timePart.second
                 );
             } else {
               // Simple HH:mm:ss split
               final parts = authTimeStr.split(':');
               if (parts.length >= 2) {
                 final h = int.parse(parts[0]);
                 final m = int.parse(parts[1]);
                 final s = parts.length > 2 ? int.tryParse(parts[2].split('.')[0]) ?? 0 : 0;
                 timestamp = DateTime.utc(
                   timestamp.year, timestamp.month, timestamp.day,
                   h, m, s
                 ).toLocal();
               }
             }
          } catch (_) {
            // fallback, keep datePart
          }
        }
      }
    }

    // 3. Parse Code/Name
    final code = json['attendCode'] ?? json['AttendCode'] ?? '';

    // 4. Determine Action (CheckIn/CheckOut)
    // If API doesn't return type, we default to checkIn, but we will infer it later in the Bloc if needed by sorting.
    // For now, let's look for a 'type' field if it exists, otherwise default to CheckIn.
    // NOTE: The previous logic (id % 2) was mock. We need 'AuthType' or similar?
    // If undefined, we can't be sure. Let's assume CheckIn for now unless specified.
    return AttendanceLog(
      id: id,
      userName: code.toString().trim().isEmpty ? 'Chấm công' : "Nhân viên $code",
      subtitle: "Vào/Ra ca trên điện thoại",
      timestamp: timestamp,
      action: AttendanceAction.checkIn, // Will be recalculated in Bloc/UI based on sequence if needed
    );
  }

  // Helper to update action (e.g. from Bloc)
  AttendanceLog copyWith({AttendanceAction? action}) {
    return AttendanceLog(
      id: id,
      userName: userName,
      subtitle: subtitle,
      timestamp: timestamp,
      action: action ?? this.action,
    );
  }
}