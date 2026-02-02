enum CheckAction { checkIn, checkOut }

class CheckInResult {
  final CheckAction action;
  final DateTime timestamp;

  const CheckInResult({
    required this.action,
    required this.timestamp,
  });
}
