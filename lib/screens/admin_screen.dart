import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> _fetchStats() async {
    final dealsCount = await supabase.from('deals').count(CountOption.exact);
    final bookingsCount = await supabase.from('bookings').count(CountOption.exact);
    final profiles = await supabase.from('profiles').select();

    return {
      'deals': dealsCount,
      'bookings': bookingsCount,
      'profiles': profiles as List<dynamic>,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Administration Baraka", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Déconnexion",
            onPressed: () async {
              await supabase.auth.signOut();
            },
          )
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchStats(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final stats = snapshot.data!;
          final List profiles = stats['profiles'];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  _statCard("Deals créés", stats['deals'].toString(), Colors.teal),
                  const SizedBox(width: 12),
                  _statCard("Réservations", stats['bookings'].toString(), Colors.orange),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                "Comptes utilisateurs & Rôles",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...profiles.map((p) => Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: p['role'] == 'admin'
                            ? Colors.purple.shade100
                            : (p['role'] == 'merchant' ? Colors.blue.shade100 : Colors.grey.shade200),
                        child: Icon(
                          p['role'] == 'admin'
                              ? Icons.admin_panel_settings
                              : (p['role'] == 'merchant' ? Icons.storefront : Icons.person),
                          color: Colors.black87,
                        ),
                      ),
                      title: Text(p['email'] ?? 'Sans email'),
                      subtitle: Text("Rôle: ${p['role']}" +
                          (p['business_name'] != null ? " • ${p['business_name']}" : "")),
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
