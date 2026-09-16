import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/admin_screen.dart';
import 'screens/merchant_dashboard_screen.dart';
import 'screens/my_passes_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://uagtvliyqqhdoyrbnjgh.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVhZ3R2bGl5cXFoZG95cmJuamdoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODkzMjUxODcsImV4cCI6MjEwNDkwMTE4N30.YnKBxUfWkUkakMQsGKrQ_CQAwzF1DXMwg_wxWxfuN2Q',
  );

  runApp(const BarakaApp());
}

final supabase = Supabase.instance.client;

class BarakaApp extends StatelessWidget {
  const BarakaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Baraka Marrakech',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00897B),
          primary: const Color(0xFF00897B),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      ),
      home: const MainHomeScreen(),
    );
  }
}

// -------------------------------------------------------------
// Modèle DealItem
// -------------------------------------------------------------
class DealItem {
  final String id;
  final String title;
  final String businessName;
  final double originalPrice;
  final double discountedPrice;
  final int remainingCount;
  final String location;
  final double latitude;
  final double longitude;
  final String imageUrl;
  final DateTime expiresAt;

  DealItem({
    required this.id,
    required this.title,
    required this.businessName,
    required this.originalPrice,
    required this.discountedPrice,
    required this.remainingCount,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    required this.expiresAt,
  });

  int get discountPercentage =>
      (((originalPrice - discountedPrice) / originalPrice) * 100).round();

  factory DealItem.fromMap(Map<String, dynamic> map) {
    return DealItem(
      id: map['id']?.toString() ?? '',
      title: map['title'] ?? 'Offre flash',
      businessName: map['business_name'] ?? 'Établissement',
      originalPrice: (map['original_price'] as num?)?.toDouble() ?? 0.0,
      discountedPrice: (map['discounted_price'] as num?)?.toDouble() ?? 0.0,
      remainingCount: (map['remaining_count'] as num?)?.toInt() ?? 0,
      location: map['location'] ?? 'Marrakech',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 31.6295,
      longitude: (map['longitude'] as num?)?.toDouble() ?? -7.9811,
      imageUrl:
          map['image_url'] ??
          'https://images.unsplash.com/photo-1541544741938-0af808871cc0',
      expiresAt:
          DateTime.tryParse(map['expires_at'] ?? '') ??
          DateTime.now().add(const Duration(hours: 4)),
    );
  }
}

// -------------------------------------------------------------
// Écran Principal
// -------------------------------------------------------------
class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _currentIndex = 0;
  int _passesRefreshKey = 0; // Incrémenté pour forcer un rechargement de MyPassesScreen
  double _userLat = 31.6258;
  double _userLng = -7.9891;
  String? _userRole;
  bool _isLoadingRole = false;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _initGps();
    _fetchUserRole();
    _authSub = supabase.auth.onAuthStateChange.listen((_) {
      _fetchUserRole();
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _fetchUserRole() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _userRole = null;
          _isLoadingRole = false;
        });
      }
      return;
    }

    setState(() => _isLoadingRole = true);
    try {
      final profile = await supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      final role = profile?['role']?.toString().toLowerCase() ??
          user.userMetadata?['role']?.toString().toLowerCase() ??
          'client';

      if (mounted) {
        setState(() {
          _userRole = role;
          _isLoadingRole = false;
        });
      }
    } catch (_) {
      final metaRole =
          user.userMetadata?['role']?.toString().toLowerCase() ?? 'client';
      if (mounted) {
        setState(() {
          _userRole = metaRole;
          _isLoadingRole = false;
        });
      }
    }
  }

  Future<void> _initGps() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
      if (mounted) {
        setState(() {
          _userLat = pos.latitude;
          _userLng = pos.longitude;
        });
      }
    } catch (_) {}
  }

  void _openAuthModal({VoidCallback? onSuccess}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AuthPage(
          onAuthSuccess: () {
            Navigator.pop(context);
            _fetchUserRole();
            if (onSuccess != null) onSuccess();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    return Scaffold(
      appBar: _currentIndex == 0
          ? AppBar(
              title: const Text(
                "Baraka Marrakech",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.confirmation_number_outlined,
                      color: Color(0xFF00897B)),
                  tooltip: "Mes Pass Réservés",
                  onPressed: () => setState(() => _currentIndex = 1),
                ),
                if (user == null)
                  TextButton.icon(
                    onPressed: () => _openAuthModal(),
                    icon: const Icon(Icons.login, color: Color(0xFF00897B)),
                    label: const Text(
                      "Connexion",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00897B),
                      ),
                    ),
                  )
                else ...[
                  if (_userRole != null)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _userRole == 'admin'
                            ? Colors.purple.shade50
                            : (_userRole == 'merchant'
                                ? const Color(0xFFE0F2F1)
                                : Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _userRole == 'admin'
                              ? Colors.purple.shade200
                              : (_userRole == 'merchant'
                                  ? const Color(0xFF80CBC4)
                                  : Colors.grey.shade300),
                        ),
                      ),
                      child: Text(
                        _userRole == 'admin'
                            ? 'Admin'
                            : (_userRole == 'merchant' ? 'Pro' : 'Client'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _userRole == 'admin'
                              ? Colors.purple.shade900
                              : (_userRole == 'merchant'
                                  ? const Color(0xFF00695C)
                                  : Colors.grey.shade800),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Center(
                      child: Text(
                        user.email?.split('@').first ?? 'Connecté',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout),
                    tooltip: "Déconnexion",
                    onPressed: () async {
                      await supabase.auth.signOut();
                      setState(() {
                        _userRole = null;
                        _currentIndex = 0;
                      });
                    },
                  ),
                ],
                const SizedBox(width: 8),
              ],
            )
          : null,
      body: _buildCurrentBody(user),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.local_offer_outlined),
            selectedIcon: Icon(Icons.local_offer),
            label: 'Bons plans',
          ),
          const NavigationDestination(
            icon: Icon(Icons.confirmation_number_outlined),
            selectedIcon: Icon(Icons.confirmation_number),
            label: 'Mes Pass',
          ),
          NavigationDestination(
            icon: Icon(
              _userRole == 'admin'
                  ? Icons.admin_panel_settings_outlined
                  : Icons.storefront_outlined,
            ),
            selectedIcon: Icon(
              _userRole == 'admin'
                  ? Icons.admin_panel_settings
                  : Icons.storefront,
            ),
            label: _userRole == 'admin' ? 'Administration' : 'Espace Pro',
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentBody(User? user) {
    if (_currentIndex == 0) {
      return FeedView(
        userLat: _userLat,
        userLng: _userLng,
        onRequireAuth: (action) => _openAuthModal(onSuccess: action),
        onOpenMyPasses: () => setState(() {
          _passesRefreshKey++;
          _currentIndex = 1;
        }),
      );
    }

    // Onglet 1 : Mes Pass (Réservations sauvegardées)
    if (_currentIndex == 1) {
      return MyPassesScreen(
        key: ValueKey(_passesRefreshKey),
        onGoToFeed: () => setState(() => _currentIndex = 0),
        onLoginRequested: () => _openAuthModal(),
      );
    }

    // Onglet 2 : Espace Pro ou Administration
    if (user == null) {
      return ProLoginGuard(onLoginRequested: () => _openAuthModal());
    }

    if (_isLoadingRole) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_userRole == 'admin') {
      return AdminScreen(
        onSwitchToPro: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MerchantDashboardScreen(
                onOfferPublished: () => setState(() => _currentIndex = 0),
              ),
            ),
          );
        },
      );
    } else if (_userRole == 'merchant') {
      return MerchantDashboardScreen(
        onOfferPublished: () => setState(() => _currentIndex = 0),
      );
    } else {
      return ClientGuardView(
        onGoToFeed: () => setState(() => _currentIndex = 0),
        onGoToPasses: () => setState(() => _currentIndex = 1),
        onLogout: () async {
          await supabase.auth.signOut();
          setState(() {
            _userRole = null;
            _currentIndex = 0;
          });
        },
      );
    }
  }
}

// -------------------------------------------------------------
// Écran Garde Espace Pro (Non Connecté)
// -------------------------------------------------------------
class ProLoginGuard extends StatelessWidget {
  final VoidCallback onLoginRequested;

  const ProLoginGuard({super.key, required this.onLoginRequested});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Espace Professionnel",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
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
                child: const Icon(
                  Icons.storefront_outlined,
                  size: 64,
                  color: Color(0xFF00897B),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Espace Professionnel & Partenaires",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Connectez-vous à votre compte commerçant pour publier vos offres flash et valider les pass clients en temps réel.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, height: 1.4),
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: onLoginRequested,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00897B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.login),
                label: const Text(
                  "Se connecter / S'inscrire",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// Écran Garde Espace Client (Connecté en tant que client)
// -------------------------------------------------------------
class ClientGuardView extends StatelessWidget {
  final VoidCallback onGoToFeed;
  final VoidCallback onGoToPasses;
  final VoidCallback onLogout;

  const ClientGuardView({
    super.key,
    required this.onGoToFeed,
    required this.onGoToPasses,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Espace Partenaire & Pro",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lock_outline,
                    size: 54, color: Colors.amber.shade800),
              ),
              const SizedBox(height: 18),
              const Text(
                "Espace Réservé aux Partenaires",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Vous êtes actuellement connecté avec un compte Client.\n\nCet espace est réservé aux commerçants partenaires pour publier leurs bons plans et valider les pass, ainsi qu'aux administrateurs.",
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: Colors.black54, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onGoToPasses,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00897B),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.confirmation_number),
                label: const Text("Voir mes Pass Réservés",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: onGoToFeed,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF00897B),
                  side: const BorderSide(color: Color(0xFF00897B)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.local_offer),
                label: const Text("Découvrir les Bons Plans",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: onLogout,
                icon: const Icon(Icons.logout, size: 18, color: Colors.redAccent),
                label: const Text(
                  "Se déconnecter / Changer de compte",
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// Flux Public des Deals
// -------------------------------------------------------------
class FeedView extends StatefulWidget {
  final double userLat;
  final double userLng;
  final void Function(VoidCallback action) onRequireAuth;
  final VoidCallback? onOpenMyPasses;

  const FeedView({
    super.key,
    required this.userLat,
    required this.userLng,
    required this.onRequireAuth,
    this.onOpenMyPasses,
  });

  @override
  State<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<FeedView> {
  late Future<List<DealItem>> _dealsFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _dealsFuture = _fetchDeals();
    });
  }

  Future<List<DealItem>> _fetchDeals() async {
    final nowIso = DateTime.now().toIso8601String();
    final res = await supabase
        .from('deals')
        .select()
        .gt('expires_at', nowIso)
        .gt('remaining_count', 0)
        .order('created_at', ascending: false);

    return (res as List).map((r) => DealItem.fromMap(r)).toList();
  }

  void _handleBookRequest(DealItem deal) {
    final user = supabase.auth.currentUser;
    if (user == null) {
      widget.onRequireAuth(() => _executeBooking(deal));
    } else {
      _executeBooking(deal);
    }
  }

  Future<void> _executeBooking(DealItem deal) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final code = (100000 + math.Random().nextInt(900000)).toString();

    try {
      // 1. Décrémenter le compteur du deal
      await supabase
          .from('deals')
          .update({'remaining_count': deal.remainingCount - 1})
          .eq('id', deal.id);

      // 2. Insérer dans bookings (sans user_id, la colonne n'existe pas dans ce schéma)
      await supabase.from('bookings').insert({
        'deal_id': deal.id,
        'pass_code': code,
        'status': 'reserve',
      });

      // 3. Sauvegarder le pass_code localement pour que MyPassesScreen puisse le retrouver
      final prefs = await SharedPreferences.getInstance();
      final existingJson = prefs.getString('my_pass_codes_${user.id}') ?? '[]';
      final List<dynamic> existing = jsonDecode(existingJson);
      existing.add(code);
      await prefs.setString('my_pass_codes_${user.id}', jsonEncode(existing));

      // 4. Insérer dans passes (compatibilité secondaire — erreurs ignorées)
      try {
        await supabase.from('passes').insert({
          'deal_id': deal.id,
          'user_id': user.id,
          'code': code,
          'status': 'active',
        });
      } catch (_) {}

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PassResultPage(
            deal: deal,
            code: code,
            onGoToMyPasses: () {
              Navigator.pop(context);
              if (widget.onOpenMyPasses != null) {
                widget.onOpenMyPasses!();
              }
            },
          ),
        ),
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      // Si l'insert bookings échoue, on réincrémente le compteur pour éviter une perte
      try {
        await supabase
            .from('deals')
            .update({'remaining_count': deal.remainingCount})
            .eq('id', deal.id);
      } catch (_) {}
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Échec du blocage : $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DealItem>>(
      future: _dealsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Erreur : ${snapshot.error}",
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _refresh,
                    child: const Text("Réessayer"),
                  ),
                ],
              ),
            ),
          );
        }

        final deals = snapshot.data ?? [];
        if (deals.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.sentiment_dissatisfied,
                  size: 50,
                  color: Colors.grey,
                ),
                const SizedBox(height: 10),
                const Text(
                  "Aucun bon plan disponible pour l'instant.",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: _refresh,
                  child: const Text("Actualiser"),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: deals.length,
            itemBuilder: (context, i) {
              final deal = deals[i];
              return DealCardWidget(
                deal: deal,
                userLat: widget.userLat,
                userLng: widget.userLng,
                onTap: () {
                  // Clic carte : Voir les détails (accessible à tous sans connexion)
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DealDetailPage(
                        deal: deal,
                        userLat: widget.userLat,
                        userLng: widget.userLng,
                        onBook: () => _handleBookRequest(deal),
                      ),
                    ),
                  );
                },
                onBook: () => _handleBookRequest(deal),
              );
            },
          ),
        );
      },
    );
  }
}

// -------------------------------------------------------------
// Carte Deal
// -------------------------------------------------------------
class DealCardWidget extends StatefulWidget {
  final DealItem deal;
  final double userLat;
  final double userLng;
  final VoidCallback onTap;
  final VoidCallback onBook;

  const DealCardWidget({
    super.key,
    required this.deal,
    required this.userLat,
    required this.userLng,
    required this.onTap,
    required this.onBook,
  });

  @override
  State<DealCardWidget> createState() => _DealCardWidgetState();
}

class _DealCardWidgetState extends State<DealCardWidget> {
  Timer? _timer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _update();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _update());
  }

  void _update() {
    final diff = widget.deal.expiresAt.difference(DateTime.now());
    if (mounted) {
      setState(() => _timeLeft = diff.isNegative ? Duration.zero : diff);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  double _getDistanceKm() {
    const double r = 6371.0;
    final dLat = (widget.deal.latitude - widget.userLat) * (math.pi / 180.0);
    final dLon = (widget.deal.longitude - widget.userLng) * (math.pi / 180.0);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(widget.userLat * (math.pi / 180.0)) *
            math.cos(widget.deal.latitude * (math.pi / 180.0)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return r * (2 * math.atan2(math.sqrt(a), math.sqrt(1 - a)));
  }

  @override
  Widget build(BuildContext context) {
    final h = _timeLeft.inHours.toString().padLeft(2, '0');
    final m = (_timeLeft.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_timeLeft.inSeconds % 60).toString().padLeft(2, '0');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.network(
                  widget.deal.imageUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 160,
                    color: Colors.grey.shade200,
                    child: const Icon(
                      Icons.image_not_supported,
                      size: 40,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00897B),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "-${widget.deal.discountPercentage}%",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "$h:$m:$s",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.deal.businessName.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        "${_getDistanceKm().toStringAsFixed(1)} km",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00897B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.deal.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            "${widget.deal.discountedPrice.toStringAsFixed(0)} MAD",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF00897B),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "${widget.deal.originalPrice.toStringAsFixed(0)} MAD",
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: widget.deal.remainingCount > 0
                            ? widget.onBook
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00897B),
                          foregroundColor: Colors.white,
                        ),
                        child: Text("Bloquer (${widget.deal.remainingCount})"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// Écran Détails d'un Deal (Accessible à tous)
// -------------------------------------------------------------
class DealDetailPage extends StatelessWidget {
  final DealItem deal;
  final double userLat;
  final double userLng;
  final VoidCallback onBook;

  const DealDetailPage({
    super.key,
    required this.deal,
    required this.userLat,
    required this.userLng,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(deal.businessName)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              deal.imageUrl,
              height: 240,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00897B),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "-${deal.discountPercentage}%",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        "${deal.remainingCount} restant(s)",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    deal.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        deal.location,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Tarif avec Baraka :",
                        style: TextStyle(fontSize: 16),
                      ),
                      Row(
                        children: [
                          Text(
                            "${deal.originalPrice.toStringAsFixed(0)} MAD",
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey.shade400,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "${deal.discountedPrice.toStringAsFixed(0)} MAD",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00897B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onBook();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00897B),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        "Bloquer mon pass maintenant",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// Écran Authentification
// -------------------------------------------------------------
class AuthPage extends StatefulWidget {
  final VoidCallback? onAuthSuccess;

  const AuthPage({super.key, this.onAuthSuccess});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _businessNameCtrl = TextEditingController();
  String _selectedRole = 'client'; // 'client' ou 'merchant'
  bool _isSignUp = false;
  bool _loading = false;

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pwd = _pwdCtrl.text.trim();
    final bName = _businessNameCtrl.text.trim();

    if (email.isEmpty || pwd.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Email valide et mot de passe (min 6 car.) requis."),
        ),
      );
      return;
    }

    if (_isSignUp && _selectedRole == 'merchant' && bName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez renseigner le nom de votre établissement."),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      if (_isSignUp) {
        final res = await supabase.auth.signUp(
          email: email,
          password: pwd,
          data: {
            'role': _selectedRole,
            if (_selectedRole == 'merchant') 'business_name': bName,
          },
        );

        if (res.user != null) {
          try {
            await supabase.from('profiles').upsert({
              'id': res.user!.id,
              'email': email,
              'role': _selectedRole,
              if (_selectedRole == 'merchant') 'business_name': bName,
            });
          } catch (_) {}
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Compte créé avec succès !")),
          );
        }
      } else {
        await supabase.auth.signInWithPassword(email: email, password: pwd);
      }

      if (mounted && widget.onAuthSuccess != null) {
        widget.onAuthSuccess!();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur d'authentification : $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    _businessNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isSignUp ? "Créer un compte" : "Connexion")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.flash_on, size: 60, color: Color(0xFF00897B)),
              const SizedBox(height: 12),
              const Text(
                "BARAKA",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: Color(0xFF00897B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _isSignUp
                    ? "Créez votre compte pour commencer"
                    : "Connectez-vous pour continuer",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // Choix du type de compte lors de l'inscription
              if (_isSignUp) ...[
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person, size: 16),
                            SizedBox(width: 6),
                            Text("Client"),
                          ],
                        ),
                        selected: _selectedRole == 'client',
                        selectedColor: const Color(0xFFE0F2F1),
                        onSelected: (val) {
                          if (val) setState(() => _selectedRole = 'client');
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ChoiceChip(
                        label: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.storefront, size: 16),
                            SizedBox(width: 6),
                            Text("Commerçant"),
                          ],
                        ),
                        selected: _selectedRole == 'merchant',
                        selectedColor: const Color(0xFFE0F2F1),
                        onSelected: (val) {
                          if (val) setState(() => _selectedRole = 'merchant');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Adresse email",
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _pwdCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Mot de passe",
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
              ),

              if (_isSignUp && _selectedRole == 'merchant') ...[
                const SizedBox(height: 14),
                TextField(
                  controller: _businessNameCtrl,
                  decoration: const InputDecoration(
                    labelText: "Nom de votre établissement",
                    hintText: "Ex : Riad Jasmine, Café de la Poste...",
                    prefixIcon: Icon(Icons.store),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00897B),
                    foregroundColor: Colors.white,
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_isSignUp ? "S'inscrire" : "Se connecter"),
                ),
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: () => setState(() => _isSignUp = !_isSignUp),
                child: Text(
                  _isSignUp
                      ? "Déjà un compte ? Se connecter"
                      : "Nouveau ? Créer un compte",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// Écran Pass QR Code Résultat
// -------------------------------------------------------------
class PassResultPage extends StatelessWidget {
  final DealItem deal;
  final String code;
  final VoidCallback? onGoToMyPasses;

  const PassResultPage({
    super.key,
    required this.deal,
    required this.code,
    this.onGoToMyPasses,
  });

  @override
  Widget build(BuildContext context) {
    final payload = jsonEncode({'deal_id': deal.id, 'code': code});

    return Scaffold(
      backgroundColor: const Color(0xFF00897B),
      appBar: AppBar(
        title: const Text("Pass Baraka", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      deal.businessName.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      deal.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 18),
                    QrImageView(
                      data: payload,
                      version: QrVersions.auto,
                      size: 190.0,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Color(0xFF00897B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Code secret à présenter sur place :",
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      code,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 6,
                        color: Color(0xFF00897B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "À régler sur place : ${deal.discountedPrice.toStringAsFixed(0)} MAD",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 18),
                    // Notification de sauvegarde automatique
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2F1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.cloud_done, color: Color(0xFF00897B), size: 22),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Pass sauvegardé automatiquement dans l'onglet 'Mes Pass' tant qu'il n'est pas utilisé ou expiré.",
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF00695C),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (onGoToMyPasses != null)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: onGoToMyPasses,
                          icon: const Icon(Icons.confirmation_number),
                          label: const Text("Voir tous mes pass sauvegardés"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00897B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// Espace Commerçant
// -------------------------------------------------------------
class MerchantView extends StatefulWidget {
  final VoidCallback onOfferPublished;

  const MerchantView({super.key, required this.onOfferPublished});

  @override
  State<MerchantView> createState() => _MerchantViewState();
}

class _MerchantViewState extends State<MerchantView> {
  final _businessCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _locCtrl = TextEditingController(text: "Guéliz, Marrakech");
  final _origCtrl = TextEditingController();
  final _discCtrl = TextEditingController();
  final _stockCtrl = TextEditingController(text: "5");
  bool _loading = false;

  Future<void> _publish() async {
    final title = _titleCtrl.text.trim();
    final business = _businessCtrl.text.trim();
    final original = double.tryParse(_origCtrl.text.trim()) ?? 0;
    final discounted = double.tryParse(_discCtrl.text.trim()) ?? 0;
    final stock = int.tryParse(_stockCtrl.text.trim()) ?? 1;

    if (title.isEmpty || business.isEmpty || original <= 0 || discounted <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez remplir correctement les champs"),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final expires = DateTime.now()
          .add(const Duration(hours: 4))
          .toIso8601String();

      await supabase.from('deals').insert({
        'title': title,
        'business_name': business,
        'original_price': original,
        'discounted_price': discounted,
        'remaining_count': stock,
        'location': _locCtrl.text.trim(),
        'latitude': 31.6346,
        'longitude': -8.0125,
        'image_url':
            'https://images.unsplash.com/photo-1541544741938-0af808871cc0',
        'expires_at': expires,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Offre flash publiée avec succès !")),
      );
      widget.onOfferPublished();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur de publication : $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _businessCtrl.dispose();
    _titleCtrl.dispose();
    _locCtrl.dispose();
    _origCtrl.dispose();
    _discCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Publier un bon plan flash",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _businessCtrl,
            decoration: const InputDecoration(
              labelText: "Nom de l'établissement",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: "Titre de l'offre (ex: Tajine Kefta + Thé)",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _locCtrl,
            decoration: const InputDecoration(
              labelText: "Quartier",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _origCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Prix normal (MAD)",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _discCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Prix réduit (MAD)",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _stockCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Quantité disponible",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _loading ? null : _publish,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00897B),
                foregroundColor: Colors.white,
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Publier maintenant"),
            ),
          ),
        ],
      ),
    );
  }
}
