import 'deal.dart';

class Booking {
  final String id;
  final Deal deal;
  final String passCode;
  final DateTime bookedAt;

  Booking({
    required this.id,
    required this.deal,
    required this.passCode,
    required this.bookedAt,
  });
}