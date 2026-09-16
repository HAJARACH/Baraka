import 'deal.dart';

class Booking {
  final String id;
  final Deal deal;
  final String passCode;
  final String status; // 'reserve', 'utilise', 'consomme'
  final DateTime bookedAt;

  Booking({
    required this.id,
    required this.deal,
    required this.passCode,
    this.status = 'reserve',
    required this.bookedAt,
  });

  bool get isRedeemed => status == 'utilise' || status == 'consomme';

  bool get isExpired => deal.expiresAt.isBefore(DateTime.now());

  // Actif tant que non consommé par le commerçant ET non expiré
  bool get isActive => !isRedeemed && !isExpired;

  Duration get remainingTime {
    final now = DateTime.now();
    if (deal.expiresAt.isBefore(now)) return Duration.zero;
    return deal.expiresAt.difference(now);
  }

  String get remainingTimeFormatted {
    final rem = remainingTime;
    if (rem == Duration.zero) return "Expiré";
    final hours = rem.inHours;
    final minutes = rem.inMinutes.remainder(60);
    if (hours > 0) {
      return "${hours}h ${minutes}m restantes";
    }
    return "${minutes}m restantes";
  }

  factory Booking.fromMap(Map<String, dynamic> map) {
    final dealData = map['deals'] as Map<String, dynamic>? ?? {};
    return Booking(
      id: map['id']?.toString() ?? '',
      deal: Deal.fromMap(dealData),
      passCode: map['pass_code']?.toString() ?? map['code']?.toString() ?? '',
      status: map['status']?.toString() ?? 'reserve',
      bookedAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}