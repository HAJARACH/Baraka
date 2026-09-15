import 'package:flutter/material.dart';
import '../models/booking.dart';
import 'pass_screen.dart';

class MyPassesScreen extends StatelessWidget {
  final List<Booking> bookings;

  const MyPassesScreen({super.key, required this.bookings});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Mes Pass Réservés",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ),
      backgroundColor: const Color(0xFFF8F9FA),
      body: bookings.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.confirmation_number_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    "Aucun pass réservé pour l'instant",
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        booking.deal.imageUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(
                      booking.deal.businessName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(booking.deal.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(
                          "Code : ${booking.passCode}",
                          style: const TextStyle(color: Color(0xFF00897B), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.qr_code_2, color: Color(0xFF00897B), size: 30),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PassScreen(
                            deal: booking.deal,
                            passCode: booking.passCode,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
