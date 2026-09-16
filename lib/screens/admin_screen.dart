import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import 'merchant_dashboard_screen.dart';

class AdminScreen extends StatefulWidget {
  final VoidCallback? onSwitchToPro;
  const AdminScreen({super.key, this.onSwitchToPro});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final supabase = Supabase.instance.client;
  bool _isLoading = false;

  Future<Map<String, dynamic>> _fetchStatsAndData() async {
    final dealsCount = await supabase.from('deals').count(CountOption.exact);
    final bookingsCount =
        await supabase.from('bookings').count(CountOption.exact);
    final profiles = await supabase.from('profiles').select().order('role');
    final deals = await supabase
        .from('deals')
        .select()
        .order('created_at', ascending: false);

    return {
      'dealsCount': dealsCount,
      'bookingsCount': bookingsCount,
      'profiles': profiles as List<dynamic>,
      'deals': deals as List<dynamic>,
    };
  }

  Future<void> _updateUserRole(String userId, String newRole) async {
    setState(() => _isLoading = true);
    try {
      await supabase
          .from('profiles')
          .update({'role': newRole})
          .eq('id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Rôle mis à jour en '$newRole' avec succès !"),
            backgroundColor: BarakaColors.primary,
          ),
        );
        setState(() {}); // Rafraîchit l'affichage
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors du changement de rôle : $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteDeal(String dealId, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Supprimer cette offre ?"),
        content: Text("Êtes-vous sûr de vouloir modérer et supprimer le deal \"$title\" ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Supprimer", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await supabase.from('deals').delete().eq('id', dealId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Offre supprimée de la plateforme avec succès."),
            backgroundColor: BarakaColors.primary,
          ),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur suppression : $e"),
            backgroundColor: BarakaColors.terracotta,
          ),
        );
      }
    }
  }

  void _openProView() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const Scaffold(
          body: MerchantDashboardScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: BarakaColors.background,
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: BarakaColors.sage,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.admin_panel_settings, color: BarakaColors.primary),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Administration Baraka",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Text(
                    "Supervision de la plateforme",
                    style: TextStyle(fontSize: 11, color: BarakaColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          backgroundColor: Colors.white,
          foregroundColor: BarakaColors.textPrimary,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.storefront, color: BarakaColors.primary),
              tooltip: "Aperçu Espace Commerçant",
              onPressed: _openProView,
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: "Rafraîchir",
              onPressed: () => setState(() {}),
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: BarakaColors.terracotta),
              tooltip: "Déconnexion",
              onPressed: () async {
                await supabase.auth.signOut();
              },
            ),
          ],
          bottom: const TabBar(
            labelColor: BarakaColors.primary,
            indicatorColor: BarakaColors.primary,
            indicatorWeight: 3,
            tabs: [
              Tab(
                icon: Icon(Icons.dashboard_outlined),
                text: "Utilisateurs & KPIs",
              ),
              Tab(
                icon: Icon(Icons.local_offer_outlined),
                text: "Modération Deals",
              ),
            ],
          ),
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _fetchStatsAndData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting || _isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: BarakaColors.primary),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                      const SizedBox(height: 12),
                      Text("Erreur lors du chargement : ${snapshot.error}"),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => setState(() {}),
                        child: const Text("Réessayer"),
                      ),
                    ],
                  ),
                ),
              );
            }

            final data = snapshot.data!;
            final int dealsCount = data['dealsCount'] ?? 0;
            final int bookingsCount = data['bookingsCount'] ?? 0;
            final List profiles = data['profiles'] ?? [];
            final List deals = data['deals'] ?? [];

            final int merchantsCount =
                profiles.where((p) => p['role'] == 'merchant').length;
            final int clientsCount =
                profiles.where((p) => p['role'] == 'client').length;
            final int adminsCount =
                profiles.where((p) => p['role'] == 'admin').length;

            return TabBarView(
              children: [
                // Tab 1 : KPIs & Gestion Utilisateurs
                RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Bannière Admin
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [BarakaColors.primaryDark, BarakaColors.primary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.shield_outlined,
                                color: Colors.white, size: 36),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Mode Administrateur Actif",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Vous gérez tous les comptes, rôles et offres du système Baraka.",
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.deepPurple,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              onPressed: _openProView,
                              icon: const Icon(Icons.visibility, size: 16),
                              label: const Text("Vue Pro"),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Cartes KPI
                      Row(
                        children: [
                          _kpiCard(
                            title: "Deals Actifs",
                            value: dealsCount.toString(),
                            icon: Icons.local_offer,
                            color: BarakaColors.primary,
                          ),
                          const SizedBox(width: 10),
                          _kpiCard(
                            title: "Réservations",
                            value: bookingsCount.toString(),
                            icon: Icons.confirmation_number,
                            color: BarakaColors.terracotta,
                          ),
                          const SizedBox(width: 10),
                          _kpiCard(
                            title: "Utilisateurs",
                            value: profiles.length.toString(),
                            icon: Icons.people,
                            color: BarakaColors.primaryLight,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Ventilation des comptes
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _rolePill("Admins", adminsCount, BarakaColors.terracotta),
                            _rolePill("Commerçants", merchantsCount, BarakaColors.primary),
                            _rolePill("Clients", clientsCount, Colors.blueGrey),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Titre liste utilisateurs
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Comptes Utilisateurs & Rôles",
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: BarakaColors.sage,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "${profiles.length} total",
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: BarakaColors.primary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Liste des profils
                      ...profiles.map((p) {
                        final role = p['role'] ?? 'client';
                        final isCurrent = p['id'] == supabase.auth.currentUser?.id;

                        return Card(
                          elevation: 0,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isCurrent
                                  ? BarakaColors.primary
                                  : Colors.grey.shade200,
                              width: isCurrent ? 1.5 : 1,
                            ),
                          ),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: role == 'admin'
                                  ? BarakaColors.terracottaLight
                                  : (role == 'merchant'
                                      ? BarakaColors.sage
                                      : Colors.grey.shade100),
                              child: Icon(
                                role == 'admin'
                                    ? Icons.admin_panel_settings
                                    : (role == 'merchant'
                                        ? Icons.storefront
                                        : Icons.person),
                                color: role == 'admin'
                                    ? BarakaColors.terracotta
                                    : (role == 'merchant'
                                        ? BarakaColors.primary
                                        : Colors.grey.shade700),
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    p['email'] ?? 'Sans email',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                if (isCurrent)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.deepPurple.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      "Vous",
                                      style: TextStyle(
                                        color: Colors.deepPurple,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                p['business_name'] != null &&
                                        (p['business_name'] as String).isNotEmpty
                                    ? "Établissement: ${p['business_name']}"
                                    : "Rôle actuel : $role",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            trailing: PopupMenuButton<String>(
                              tooltip: "Changer le rôle",
                              icon: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: role == 'admin'
                                      ? BarakaColors.terracottaLight
                                      : (role == 'merchant'
                                          ? BarakaColors.sage
                                          : Colors.grey.shade100),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: role == 'admin'
                                        ? BarakaColors.terracotta
                                        : (role == 'merchant'
                                            ? BarakaColors.primary
                                            : Colors.grey.shade300),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      role.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: role == 'admin'
                                            ? BarakaColors.terracotta
                                            : (role == 'merchant'
                                                ? BarakaColors.primary
                                                : Colors.grey.shade800),
                                      ),
                                    ),
                                    const Icon(Icons.arrow_drop_down, size: 16),
                                  ],
                                ),
                              ),
                              onSelected: (newRole) {
                                if (newRole != role) {
                                  _updateUserRole(p['id'], newRole);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'client',
                                  child: Row(
                                    children: [
                                      Icon(Icons.person, color: Colors.grey, size: 18),
                                      SizedBox(width: 8),
                                      Text("Client"),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'merchant',
                                  child: Row(
                                    children: [
                                      Icon(Icons.storefront,
                                          color: BarakaColors.primary, size: 18),
                                      SizedBox(width: 8),
                                      Text("Commerçant (Pro)"),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'admin',
                                  child: Row(
                                    children: [
                                      Icon(Icons.admin_panel_settings,
                                          color: BarakaColors.terracotta, size: 18),
                                      SizedBox(width: 8),
                                      Text("Administrateur"),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                // Tab 2 : Modération des deals
                RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: deals.isEmpty
                      ? const Center(
                          child: Text("Aucune offre publiée sur la plateforme."),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: deals.length,
                          itemBuilder: (context, index) {
                            final d = deals[index];
                            final id = d['id']?.toString() ?? '';
                            final title = d['title'] ?? 'Offre sans titre';
                            final business = d['business_name'] ?? 'Établissement inconnu';
                            final origPrice = d['original_price'] ?? 0;
                            final discPrice = d['discounted_price'] ?? 0;
                            final remaining = d['remaining_count'] ?? 0;

                            return Card(
                              elevation: 0,
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              margin: const EdgeInsets.only(bottom: 10),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        d['image_url'] ??
                                            'https://images.unsplash.com/photo-1541544741938-0af808871cc0',
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          width: 60,
                                          height: 60,
                                          color: Colors.grey.shade200,
                                          child: const Icon(Icons.image_not_supported,
                                              color: Colors.grey),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            business,
                                            style: const TextStyle(
                                                color: BarakaColors.primary,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Text(
                                                "$discPrice MAD ",
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                    color: Colors.black87),
                                              ),
                                              Text(
                                                "$origPrice MAD",
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey,
                                                  decoration:
                                                      TextDecoration.lineThrough,
                                                ),
                                              ),
                                              const Spacer(),
                                              Text(
                                                "Stock: $remaining",
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: remaining > 0
                                                      ? Colors.green.shade700
                                                      : Colors.redAccent,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.redAccent),
                                      tooltip: "Modérer / Supprimer",
                                      onPressed: () => _deleteDeal(id, title),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _kpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rolePill(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          "$label: ",
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        Text(
          "$count",
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
