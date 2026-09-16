import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booking.dart';
import 'pass_screen.dart';

class MyPassesScreen extends StatefulWidget {
  final VoidCallback? onGoToFeed;
  final VoidCallback? onLoginRequested;

  const MyPassesScreen({
    super.key,
    this.onGoToFeed,
    this.onLoginRequested,
  });

  @override
  State<MyPassesScreen> createState() => _MyPassesScreenState();
}

class _MyPassesScreenState extends State<MyPassesScreen> {
  final supabase = Supabase.instance.client;
  late Future<List<Booking>> _bookingsFuture;

  @override
  void initState() {
    super.initState();
    _bookingsFuture = _fetchBookings();
  }

  void _refresh() {
    setState(() {
      _bookingsFuture = _fetchBookings();
    });
  }

  Future<List<Booking>> _fetchBookings() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    try {
      // Récupérer les codes sauvegardés localement sur l'appareil
      final prefs = await SharedPreferences.getInstance();
      final codesJson = prefs.getString('my_pass_codes_${user.id}') ?? '[]';
      final List<dynamic> rawCodes = jsonDecode(codesJson);
      final List<String> codes = rawCodes.map((e) => e.toString()).toList();

      if (codes.isEmpty) return [];

      // Récupérer les bookings correspondants depuis Supabase
      final data = await supabase
          .from('bookings')
          .select('id, pass_code, status, created_at, deals(*)')
          .inFilter('pass_code', codes)
          .order('created_at', ascending: false);

      return (data as List)
          .map((item) => Booking.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint("Erreur chargement bookings : $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Mes Pass Réservés",
              style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE0F2F1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.confirmation_number_outlined,
                      size: 60, color: Color(0xFF00897B)),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Connectez-vous pour voir vos pass",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Vos pass et QR codes réservés sont conservés en toute sécurité dans votre espace tant qu'ils ne sont pas consommés ou expirés.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, height: 1.4),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: widget.onLoginRequested,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00897B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.login),
                  label: const Text("Se connecter",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black87,
          title: const Row(
            children: [
              Icon(Icons.confirmation_number, color: Color(0xFF00897B)),
              SizedBox(width: 8),
              Text(
                "Mes Pass Réservés",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: "Rafraîchir",
              onPressed: _refresh,
            ),
          ],
          bottom: const TabBar(
            labelColor: Color(0xFF00897B),
            indicatorColor: Color(0xFF00897B),
            tabs: [
              Tab(icon: Icon(Icons.check_circle_outline), text: "Pass Actifs"),
              Tab(icon: Icon(Icons.history), text: "Historique"),
            ],
          ),
        ),
        body: FutureBuilder<List<Booking>>(
          future: _bookingsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF00897B)),
              );
            }

            final allBookings = snapshot.data ?? [];
            final activeBookings =
                allBookings.where((b) => b.isActive).toList();
            final pastBookings =
                allBookings.where((b) => !b.isActive).toList();

            return TabBarView(
              children: [
                _buildActiveTab(activeBookings),
                _buildHistoryTab(pastBookings),
              ],
            );
          },
        ),
      ),
    );
  }

  // Onglet 1 : Pass actifs
  Widget _buildActiveTab(List<Booking> activeList) {
    if (activeList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.qr_code_2_outlined,
                  size: 70, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                "Aucun pass actif pour l'instant",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Dès que vous réservez une offre flash, votre pass et votre QR Code restent sauvegardés ici jusqu'à leur encaissement.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, height: 1.4),
              ),
              const SizedBox(height: 24),
              if (widget.onGoToFeed != null)
                ElevatedButton.icon(
                  onPressed: widget.onGoToFeed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00897B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.local_offer),
                  label: const Text("Découvrir les bons plans"),
                ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: activeList.length,
        itemBuilder: (context, index) {
          final booking = activeList[index];
          final deal = booking.deal;

          return Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFF80CBC4), width: 1.5),
            ),
            margin: const EdgeInsets.only(bottom: 14),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _openPassDetail(booking),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Entête : Établissement + Badge Actif
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            deal.imageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 50,
                              height: 50,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.image, color: Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                deal.businessName.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00897B),
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                deal.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2F1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "VALIDE",
                            style: TextStyle(
                              color: Color(0xFF00897B),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // Code PIN & Compte à rebours
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Code à présenter :",
                              style: TextStyle(
                                  fontSize: 12, color: Colors.black54),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00897B).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                booking.passCode,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 3,
                                  color: Color(0xFF00897B),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.timer_outlined,
                                    size: 14, color: Colors.orange.shade800),
                                const SizedBox(width: 4),
                                Text(
                                  booking.remainingTimeFormatted,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange.shade900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${deal.discountedPrice.toStringAsFixed(0)} MAD",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Bouton Afficher QR Code
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _openPassDetail(booking),
                        icon: const Icon(Icons.qr_code, size: 18),
                        label: const Text("Ouvrir le Pass & QR Code"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00897B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Onglet 2 : Historique
  Widget _buildHistoryTab(List<Booking> pastList) {
    if (pastList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history, size: 60, color: Colors.grey.shade400),
              const SizedBox(height: 14),
              const Text(
                "Aucun pass dans l'historique",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                "Vos pass consommés chez le commerçant ou expirés apparaîtront ici.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: pastList.length,
        itemBuilder: (context, index) {
          final booking = pastList[index];
          final isRedeemed = booking.isRedeemed;

          return Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isRedeemed
                    ? const Color(0xFFE0F2F1)
                    : Colors.grey.shade100,
                child: Icon(
                  isRedeemed ? Icons.check : Icons.timer_off_outlined,
                  color: isRedeemed
                      ? const Color(0xFF00897B)
                      : Colors.grey.shade600,
                ),
              ),
              title: Text(
                booking.deal.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                "${booking.deal.businessName} • Code : ${booking.passCode}",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isRedeemed ? Colors.green.shade50 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isRedeemed ? "Consommé" : "Expiré",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isRedeemed
                        ? Colors.green.shade800
                        : Colors.grey.shade700,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openPassDetail(Booking booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PassScreen(
          deal: booking.deal,
          passCode: booking.passCode,
        ),
      ),
    ).then((_) {
      // Rafraîchir l'écran quand on revient au cas où le pass a été consommé
      _refresh();
    });
  }
}
