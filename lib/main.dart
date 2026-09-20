import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/admin_screen.dart';
import 'screens/category_hub_screen.dart';
import 'screens/establishment_detail_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/merchant_dashboard_screen.dart';
import 'screens/my_passes_screen.dart';
import 'screens/splash_screen.dart';
import 'services/favorites_service.dart';
import 'theme/app_theme.dart';
import 'utils/fuzzy_search.dart';
import 'widgets/app_background.dart';
import 'widgets/baraka_logo.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://uagtvliyqqhdoyrbnjgh.supabase.co',
    publishableKey:
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
      theme: BarakaTheme.lightTheme,
      home: const SplashScreen(),
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
  final String category;

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
    this.category = 'Général',
  });

  int get discountPercentage =>
      (((originalPrice - discountedPrice) / originalPrice) * 100).round();

  bool matchesSearch(String query) {
    return FuzzySearch.matchesDeal(
      title: title,
      businessName: businessName,
      location: location,
      category: category,
      query: query,
    );
  }

  double searchRelevance(String query) {
    return FuzzySearch.calculateRelevanceScore(
      title: title,
      businessName: businessName,
      location: location,
      category: category,
      query: query,
    );
  }

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
      category: map['category'] ?? 'Général',
    );
  }
}

// -------------------------------------------------------------
// Modèle Groupe Établissement (Multi-offres)
// -------------------------------------------------------------
class EstablishmentGroup {
  final String businessName;
  final String location;
  final double latitude;
  final double longitude;
  final String category;
  final List<DealItem> deals;

  EstablishmentGroup({
    required this.businessName,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.category,
    required this.deals,
  });

  int get totalRemaining => deals.fold(0, (sum, d) => sum + d.remainingCount);
}

// -------------------------------------------------------------
// Écran Principal
// -------------------------------------------------------------
class MainHomeScreen extends StatefulWidget {
  final String? initialMacroCategory;
  const MainHomeScreen({super.key, this.initialMacroCategory});

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
    FavoritesService.instance.init();
    _initGps();
    _fetchUserRole();
    _authSub = supabase.auth.onAuthStateChange.listen((_) {
      _fetchUserRole();
      FavoritesService.instance.loadFavorites();
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
            FavoritesService.instance.loadFavorites();
            if (onSuccess != null) onSuccess();
          },
        ),
      ),
    );
  }

  void _toggleFavoriteWithAuth(String dealId) {
    final user = supabase.auth.currentUser;
    if (user == null) {
      _openAuthModal(
        onSuccess: () async {
          final added = await FavoritesService.instance.toggleFavorite(dealId);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  added ? "Ajouté aux favoris ! ❤️" : "Retiré des favoris",
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
      );
    } else {
      FavoritesService.instance.toggleFavorite(dealId).then((added) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                added ? "Ajouté aux favoris ! ❤️" : "Retiré des favoris",
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      });
    }
  }

  Future<void> _executeBookingFromDeal(DealItem deal) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      _openAuthModal(onSuccess: () => _executeBookingFromDeal(deal));
      return;
    }

    final code = (100000 + math.Random().nextInt(900000)).toString();

    try {
      // 1. Décrémenter le compteur du deal
      await supabase
          .from('deals')
          .update({'remaining_count': deal.remainingCount - 1})
          .eq('id', deal.id);

      // 2. Insérer dans bookings
      await supabase.from('bookings').insert({
        'deal_id': deal.id,
        'pass_code': code,
        'status': 'reserve',
      });

      // 3. Sauvegarder le pass_code localement pour MyPassesScreen
      final prefs = await SharedPreferences.getInstance();
      final existingJson = prefs.getString('my_pass_codes_${user.id}') ?? '[]';
      final List<dynamic> existing = jsonDecode(existingJson);
      existing.add(code);
      await prefs.setString('my_pass_codes_${user.id}', jsonEncode(existing));

      // 4. Insérer dans passes (optionnel)
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
              setState(() {
                _passesRefreshKey++;
                _currentIndex = 2;
              });
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      try {
        await supabase
            .from('deals')
            .update({'remaining_count': deal.remainingCount})
            .eq('id', deal.id);
      } catch (_) {}
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Échec de la réservation : $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    return Scaffold(
      appBar: _currentIndex == 0
          ? AppBar(
              title: const BarakaAppBarTitle(),
              titleSpacing: 16,
              actions: [
                if (user == null)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: TextButton.icon(
                      onPressed: () => _openAuthModal(),
                      icon: const Icon(
                        Icons.login_rounded,
                        size: 18,
                        color: BarakaColors.primary,
                      ),
                      label: const Text(
                        "Connexion",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: BarakaColors.primary,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        backgroundColor: BarakaColors.sageLight,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  )
                else ...[
                  if (_userRole == 'admin' || _userRole == 'merchant')
                    Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _userRole == 'admin'
                            ? BarakaColors.terracottaLight
                            : BarakaColors.sage,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _userRole == 'admin'
                              ? BarakaColors.terracotta
                              : BarakaColors.primaryLight,
                        ),
                      ),
                      child: Text(
                        _userRole == 'admin' ? 'Admin' : 'Pro',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _userRole == 'admin'
                              ? BarakaColors.terracottaDark
                              : BarakaColors.primaryDark,
                        ),
                      ),
                    ),
                  PopupMenuButton<String>(
                    tooltip: "Mon compte",
                    offset: const Offset(0, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    icon: CircleAvatar(
                      radius: 15,
                      backgroundColor: BarakaColors.primary,
                      child: Text(
                        (user.email?.isNotEmpty == true
                                ? user.email![0].toUpperCase()
                                : 'U'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    onSelected: (val) async {
                      if (val == 'admin' || val == 'merchant') {
                        setState(() => _currentIndex = 3);
                      } else if (val == 'logout') {
                        await supabase.auth.signOut();
                        FavoritesService.instance.clear();
                        setState(() {
                          _userRole = null;
                          _currentIndex = 0;
                        });
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        enabled: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              user.email ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: BarakaColors.textPrimary,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _userRole == 'admin'
                                  ? 'Administrateur'
                                  : (_userRole == 'merchant'
                                      ? 'Commerçant Partenaire'
                                      : 'Client'),
                              style: const TextStyle(
                                fontSize: 12,
                                color: BarakaColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      if (_userRole == 'admin')
                        const PopupMenuItem(
                          value: 'admin',
                          child: Row(
                            children: [
                              Icon(
                                Icons.admin_panel_settings_outlined,
                                size: 19,
                                color: BarakaColors.primary,
                              ),
                              SizedBox(width: 10),
                              Text("Panneau Admin"),
                            ],
                          ),
                        )
                      else if (_userRole == 'merchant')
                        const PopupMenuItem(
                          value: 'merchant',
                          child: Row(
                            children: [
                              Icon(
                                Icons.storefront_outlined,
                                size: 19,
                                color: BarakaColors.primary,
                              ),
                              SizedBox(width: 10),
                              Text("Espace Pro"),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(
                              Icons.logout,
                              size: 19,
                              color: Colors.redAccent,
                            ),
                            SizedBox(width: 10),
                            Text(
                              "Déconnexion",
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.logout,
                      size: 20,
                      color: BarakaColors.textSecondary,
                    ),
                    tooltip: "Déconnexion",
                    onPressed: () async {
                      await supabase.auth.signOut();
                      FavoritesService.instance.clear();
                      setState(() {
                        _userRole = null;
                        _currentIndex = 0;
                      });
                    },
                  ),
                ],
                const SizedBox(width: 6),
              ],
            )
          : null,
      body: AppBackground(
        child: _buildCurrentBody(user),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: BarakaColors.border.withValues(alpha: 0.8),
            ),
            boxShadow: BarakaColors.floatingShadow,
          ),
          child: Row(
            children: [
              _buildNavDockItem(
                index: 0,
                label: 'Bons plans',
                icon: Icons.local_offer_outlined,
                selectedIcon: Icons.local_offer_rounded,
              ),
              _buildNavDockFavoritesItem(),
              _buildNavDockItem(
                index: 2,
                label: 'Mes Pass',
                icon: Icons.confirmation_number_outlined,
                selectedIcon: Icons.confirmation_number_rounded,
              ),
              _buildNavDockItem(
                index: 3,
                label: _userRole == 'admin' ? 'Admin' : 'Espace Pro',
                icon: _userRole == 'admin'
                    ? Icons.admin_panel_settings_outlined
                    : Icons.storefront_outlined,
                selectedIcon: _userRole == 'admin'
                    ? Icons.admin_panel_settings_rounded
                    : Icons.storefront_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavDockItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData selectedIcon,
  }) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _currentIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? BarakaColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                size: 21,
                color: isSelected ? Colors.white : BarakaColors.textSecondary,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : BarakaColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavDockFavoritesItem() {
    final isSelected = _currentIndex == 1;
    return Expanded(
      child: ValueListenableBuilder<Set<String>>(
        valueListenable: FavoritesService.instance.favoritesNotifier,
        builder: (context, favs, _) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _currentIndex = 1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? BarakaColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Badge(
                    isLabelVisible: favs.isNotEmpty,
                    label: Text(
                      '${favs.length}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: BarakaColors.terracotta,
                    child: Icon(
                      isSelected
                          ? Icons.favorite_rounded
                          : Icons.favorite_outline_rounded,
                      size: 21,
                      color: isSelected
                          ? Colors.white
                          : BarakaColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Favoris',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : BarakaColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentBody(User? user) {
    if (_currentIndex == 0) {
      return FeedView(
        userLat: _userLat,
        userLng: _userLng,
        initialMacroCategory: widget.initialMacroCategory,
        onRequireAuth: (action) => _openAuthModal(onSuccess: action),
        onOpenMyPasses: () => setState(() {
          _passesRefreshKey++;
          _currentIndex = 2;
        }),
      );
    }

    // Onglet 1 : Favoris (Sauvegardés sans forcément réserver)
    if (_currentIndex == 1) {
      return FavoritesScreen(
        userLat: _userLat,
        userLng: _userLng,
        onGoToFeed: () => setState(() => _currentIndex = 0),
        onRequireAuth: (action) => _openAuthModal(onSuccess: action),
        onBookDeal: (deal) {
          final dealItem = DealItem(
            id: deal.id,
            title: deal.title,
            businessName: deal.businessName,
            originalPrice: deal.originalPrice,
            discountedPrice: deal.discountedPrice,
            remainingCount: deal.remainingCount,
            location: deal.location,
            latitude: deal.latitude,
            longitude: deal.longitude,
            imageUrl: deal.imageUrl,
            expiresAt: deal.expiresAt,
            category: deal.category,
          );
          _executeBookingFromDeal(dealItem);
        },
        onOpenDealDetail: (deal) {
          final dealItem = DealItem(
            id: deal.id,
            title: deal.title,
            businessName: deal.businessName,
            originalPrice: deal.originalPrice,
            discountedPrice: deal.discountedPrice,
            remainingCount: deal.remainingCount,
            location: deal.location,
            latitude: deal.latitude,
            longitude: deal.longitude,
            imageUrl: deal.imageUrl,
            expiresAt: deal.expiresAt,
            category: deal.category,
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DealDetailPage(
                deal: dealItem,
                userLat: _userLat,
                userLng: _userLng,
                onBook: () => _executeBookingFromDeal(dealItem),
                onToggleFavorite: () => _toggleFavoriteWithAuth(dealItem.id),
              ),
            ),
          );
        },
      );
    }

    // Onglet 2 : Mes Pass (Réservations sauvegardées)
    if (_currentIndex == 2) {
      return MyPassesScreen(
        key: ValueKey(_passesRefreshKey),
        onGoToFeed: () => setState(() => _currentIndex = 0),
        onLoginRequested: () => _openAuthModal(),
      );
    }

    // Onglet 3 : Espace Pro ou Administration
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
        onGoToPasses: () => setState(() => _currentIndex = 2),
        onLogout: () async {
          await supabase.auth.signOut();
          FavoritesService.instance.clear();
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
                  color: BarakaColors.sage,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.storefront_outlined,
                  size: 64,
                  color: BarakaColors.primary,
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
                  backgroundColor: BarakaColors.primary,
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
                decoration: const BoxDecoration(
                  color: BarakaColors.terracottaLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline,
                  size: 54,
                  color: BarakaColors.terracotta,
                ),
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
                  backgroundColor: BarakaColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.confirmation_number),
                label: const Text(
                  "Voir mes Pass Réservés",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: onGoToFeed,
                style: OutlinedButton.styleFrom(
                  foregroundColor: BarakaColors.primary,
                  side: const BorderSide(color: BarakaColors.primary),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.local_offer),
                label: const Text(
                  "Découvrir les Bons Plans",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
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
// Options de Tri du Feed
// -------------------------------------------------------------
enum FeedSortOption {
  distance,
  expiration,
  recent,
}

// -------------------------------------------------------------
// Flux Public des Deals avec Recherche et Filtres Marrakech
// -------------------------------------------------------------
class FeedView extends StatefulWidget {
  final double userLat;
  final double userLng;
  final String? initialMacroCategory;
  final void Function(VoidCallback action) onRequireAuth;
  final VoidCallback? onOpenMyPasses;

  const FeedView({
    super.key,
    required this.userLat,
    required this.userLng,
    required this.onRequireAuth,
    this.initialMacroCategory,
    this.onOpenMyPasses,
  });

  @override
  State<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<FeedView> {
  late Future<List<DealItem>> _dealsFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late String _selectedMacroCategory;
  String _selectedCategory = 'Tous';
  String _selectedQuartier = 'Tous';
  FeedSortOption _sortOption = FeedSortOption.distance;

  static const List<Map<String, dynamic>> _alimentaireCategories = [
    {'label': 'Tous', 'icon': Icons.restaurant_menu_rounded},
    {'label': 'Restauration & Cafés', 'icon': Icons.restaurant_rounded},
  ];

  static const List<Map<String, dynamic>> _servicesCategories = [
    {'label': 'Tous', 'icon': Icons.room_service_rounded},
    {'label': 'Beauté & Bien-être', 'icon': Icons.spa_rounded},
    {'label': 'Hébergement & Séjours', 'icon': Icons.hotel_rounded},
    {'label': 'Activités & Loisirs', 'icon': Icons.attractions_rounded},
    {'label': 'Mobilité & Transports', 'icon': Icons.directions_car_rounded},
    {'label': 'Shopping & Services', 'icon': Icons.shopping_bag_rounded},
  ];

  static const List<Map<String, dynamic>> _allCategories = [
    {'label': 'Tous', 'icon': Icons.grid_view_rounded},
    {'label': 'Restauration & Cafés', 'icon': Icons.restaurant_rounded},
    {'label': 'Beauté & Bien-être', 'icon': Icons.spa_rounded},
    {'label': 'Hébergement & Séjours', 'icon': Icons.hotel_rounded},
    {'label': 'Activités & Loisirs', 'icon': Icons.attractions_rounded},
    {'label': 'Mobilité & Transports', 'icon': Icons.directions_car_rounded},
    {'label': 'Shopping & Services', 'icon': Icons.shopping_bag_rounded},
  ];

  List<Map<String, dynamic>> get _currentCategories {
    if (_selectedMacroCategory == 'Alimentaire') return _alimentaireCategories;
    if (_selectedMacroCategory == 'Services') return _servicesCategories;
    return _allCategories;
  }

  static const List<String> _quartiers = [
    'Tous',
    'Guéliz',
    'Médina',
    'Hivernage',
    'Agdal',
    'Sidi Ghanem',
    'Palmeraie',
    'Semlalia',
    'Targa',
  ];

  @override
  void initState() {
    super.initState();
    _selectedMacroCategory = widget.initialMacroCategory ?? 'Tous';
    _refresh();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  double _getDealDistanceKm(DealItem deal) {
    const double r = 6371.0;
    final dLat = (deal.latitude - widget.userLat) * (math.pi / 180.0);
    final dLon = (deal.longitude - widget.userLng) * (math.pi / 180.0);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(widget.userLat * (math.pi / 180.0)) *
            math.cos(deal.latitude * (math.pi / 180.0)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return r * (2 * math.atan2(math.sqrt(a), math.sqrt(1 - a)));
  }

  bool _isAlimentaire(DealItem deal) {
    final text =
        "${deal.title} ${deal.businessName} ${deal.category}".toLowerCase();
    return text.contains('boulang') ||
        text.contains('patiss') ||
        text.contains('pâtiss') ||
        text.contains('pain') ||
        text.contains('croissant') ||
        text.contains('viennoiserie') ||
        text.contains('bakery') ||
        text.contains('restau') ||
        text.contains('food') ||
        text.contains('plat') ||
        text.contains('repas') ||
        text.contains('traiteur') ||
        text.contains('snack') ||
        text.contains('café') ||
        text.contains('cafe') ||
        text.contains('burger') ||
        text.contains('pizza') ||
        text.contains('tajine') ||
        text.contains('couscous') ||
        text.contains('épicer') ||
        text.contains('epicer') ||
        text.contains('supermarch') ||
        text.contains('grocery') ||
        text.contains('primeur') ||
        text.contains('fruit') ||
        text.contains('légume') ||
        text.contains('alimentation') ||
        text.contains('restauration');
  }

  bool _isServices(DealItem deal) {
    final text =
        "${deal.title} ${deal.businessName} ${deal.category}".toLowerCase();
    return text.contains('fleur') ||
        text.contains('florist') ||
        text.contains('plante') ||
        text.contains('bouquet') ||
        text.contains('beauté') ||
        text.contains('beaute') ||
        text.contains('bien-être') ||
        text.contains('bien etre') ||
        text.contains('spa') ||
        text.contains('soin') ||
        text.contains('coiff') ||
        text.contains('artisan') ||
        text.contains('héberg') ||
        text.contains('heberg') ||
        text.contains('hôtel') ||
        text.contains('hotel') ||
        text.contains('riad') ||
        text.contains('activité') ||
        text.contains('activite') ||
        text.contains('loisir') ||
        text.contains('mobilité') ||
        text.contains('mobilite') ||
        text.contains('transport') ||
        text.contains('shopping') ||
        text.contains('service');
  }

  bool _matchesCategory(DealItem deal, String category) {
    if (_selectedMacroCategory == 'Alimentaire' && category == 'Tous') {
      return _isAlimentaire(deal);
    }
    if (_selectedMacroCategory == 'Services' && category == 'Tous') {
      return _isServices(deal);
    }
    if (category == 'Tous') return true;

    final dealCategory = deal.category.toLowerCase();
    final target = category.toLowerCase();

    if (dealCategory.contains(target)) return true;

    final text =
        "${deal.title} ${deal.businessName} ${deal.category}".toLowerCase();

    switch (category) {
      case 'Restauration & Cafés':
        return text.contains('restau') ||
            text.contains('café') ||
            text.contains('cafe') ||
            text.contains('food') ||
            text.contains('plat') ||
            text.contains('repas') ||
            text.contains('traiteur') ||
            text.contains('snack') ||
            text.contains('burger') ||
            text.contains('pizza') ||
            text.contains('tajine') ||
            text.contains('couscous') ||
            text.contains('boulang') ||
            text.contains('patiss') ||
            text.contains('pâtiss') ||
            text.contains('pain') ||
            text.contains('croissant') ||
            text.contains('viennoiserie') ||
            text.contains('bakery') ||
            text.contains('brunch') ||
            text.contains('coffee') ||
            text.contains('thé') ||
            text.contains('the') ||
            text.contains('boisson') ||
            text.contains('jus');
      case 'Beauté & Bien-être':
        return text.contains('beauté') ||
            text.contains('beaute') ||
            text.contains('bien-être') ||
            text.contains('bien etre') ||
            text.contains('spa') ||
            text.contains('massage') ||
            text.contains('hammam') ||
            text.contains('coiff') ||
            text.contains('barber') ||
            text.contains('esthéti') ||
            text.contains('estheti') ||
            text.contains('manucure') ||
            text.contains('pédicure') ||
            text.contains('pedicure') ||
            text.contains('ongle') ||
            text.contains('soin') ||
            text.contains('visage') ||
            text.contains('corps') ||
            text.contains('relaxation') ||
            text.contains('zen') ||
            text.contains('yoga') ||
            text.contains('fitness');
      case 'Hébergement & Séjours':
        return text.contains('héberg') ||
            text.contains('heberg') ||
            text.contains('séjour') ||
            text.contains('sejour') ||
            text.contains('hôtel') ||
            text.contains('hotel') ||
            text.contains('riad') ||
            text.contains('villa') ||
            text.contains('resort') ||
            text.contains('chambre') ||
            text.contains('suite') ||
            text.contains('nuitée') ||
            text.contains('nuitee') ||
            text.contains('nuit') ||
            text.contains('guest') ||
            text.contains('maison d\'hôte') ||
            text.contains('auberge') ||
            text.contains('lodge');
      case 'Activités & Loisirs':
        return text.contains('activité') ||
            text.contains('activite') ||
            text.contains('loisir') ||
            text.contains('excursion') ||
            text.contains('quad') ||
            text.contains('buggy') ||
            text.contains('dromadaire') ||
            text.contains('chameau') ||
            text.contains('visite') ||
            text.contains('musée') ||
            text.contains('musee') ||
            text.contains('parc') ||
            text.contains('piscine') ||
            text.contains('escape') ||
            text.contains('karting') ||
            text.contains('bowling') ||
            text.contains('cinéma') ||
            text.contains('cinema') ||
            text.contains('atelier') ||
            text.contains('cours') ||
            text.contains('sport') ||
            text.contains('balade') ||
            text.contains('tourisme') ||
            text.contains('aventure');
      case 'Mobilité & Transports':
        return text.contains('mobilité') ||
            text.contains('mobilite') ||
            text.contains('transport') ||
            text.contains('location') ||
            text.contains('voiture') ||
            text.contains('auto') ||
            text.contains('scooter') ||
            text.contains('moto') ||
            text.contains('vélo') ||
            text.contains('velo') ||
            text.contains('navette') ||
            text.contains('transfert') ||
            text.contains('taxi') ||
            text.contains('chauffeur') ||
            text.contains('vtc') ||
            text.contains('aéroport') ||
            text.contains('aeroport') ||
            text.contains('parking') ||
            text.contains('lavage');
      case 'Shopping & Services':
        return text.contains('shopping') ||
            text.contains('service') ||
            text.contains('fleur') ||
            text.contains('florist') ||
            text.contains('plante') ||
            text.contains('bouquet') ||
            text.contains('boutique') ||
            text.contains('magasin') ||
            text.contains('mode') ||
            text.contains('vêtement') ||
            text.contains('vetement') ||
            text.contains('accessoire') ||
            text.contains('bijou') ||
            text.contains('bijouterie') ||
            text.contains('artisanat') ||
            text.contains('souk') ||
            text.contains('cuir') ||
            text.contains('tapis') ||
            text.contains('poterie') ||
            text.contains('cadeau') ||
            text.contains('épicer') ||
            text.contains('epicer') ||
            text.contains('supermarch') ||
            text.contains('grocery') ||
            text.contains('primeur') ||
            text.contains('fruit') ||
            text.contains('légume') ||
            text.contains('alimentation');
      // Legacy categories for backward compatibility
      case 'Boulangerie':
        return text.contains('boulang') ||
            text.contains('patiss') ||
            text.contains('pâtiss') ||
            text.contains('pain') ||
            text.contains('croissant') ||
            text.contains('viennoiserie') ||
            text.contains('bakery');
      case 'Restaurant':
        return text.contains('restau') ||
            text.contains('food') ||
            text.contains('plat') ||
            text.contains('repas') ||
            text.contains('traiteur') ||
            text.contains('snack') ||
            text.contains('café') ||
            text.contains('cafe') ||
            text.contains('burger') ||
            text.contains('pizza') ||
            text.contains('tajine') ||
            text.contains('couscous');
      case 'Épicerie':
        return text.contains('épicer') ||
            text.contains('epicer') ||
            text.contains('supermarch') ||
            text.contains('grocery') ||
            text.contains('primeur') ||
            text.contains('fruit') ||
            text.contains('légume') ||
            text.contains('alimentation');
      case 'Fleuriste':
        return text.contains('fleur') ||
            text.contains('florist') ||
            text.contains('plante') ||
            text.contains('bouquet');
      default:
        return dealCategory.contains(target);
    }
  }

  bool _matchesQuartier(DealItem deal, String quartier) {
    if (quartier == 'Tous') return true;

    final q = quartier.toLowerCase();
    final location = deal.location.toLowerCase();
    final business = deal.businessName.toLowerCase();
    final title = deal.title.toLowerCase();

    return location.contains(q) || business.contains(q) || title.contains(q);
  }

  bool _matchesSearch(DealItem deal, String query) {
    return deal.matchesSearch(query);
  }

  List<DealItem> _applyFiltersAndSort(List<DealItem> allDeals) {
    final filtered = allDeals.where((deal) {
      final matchesCat = _matchesCategory(deal, _selectedCategory);
      final matchesQ = _matchesQuartier(deal, _selectedQuartier);
      final matchesS = _matchesSearch(deal, _searchQuery);
      return matchesCat && matchesQ && matchesS;
    }).toList();

    switch (_sortOption) {
      case FeedSortOption.distance:
        filtered.sort((a, b) =>
            _getDealDistanceKm(a).compareTo(_getDealDistanceKm(b)));
        break;
      case FeedSortOption.expiration:
        filtered.sort((a, b) => a.expiresAt.compareTo(b.expiresAt));
        break;
      case FeedSortOption.recent:
        if (_searchQuery.trim().isNotEmpty) {
          filtered.sort((a, b) => b
              .searchRelevance(_searchQuery)
              .compareTo(a.searchRelevance(_searchQuery)));
        }
        break;
    }

    return filtered;
  }

  List<EstablishmentGroup> _groupDealsByEstablishment(List<DealItem> deals) {
    final Map<String, EstablishmentGroup> map = {};
    for (final deal in deals) {
      final key = deal.businessName.trim().toLowerCase();
      if (!map.containsKey(key)) {
        map[key] = EstablishmentGroup(
          businessName: deal.businessName.trim(),
          location: deal.location,
          latitude: deal.latitude,
          longitude: deal.longitude,
          category: deal.category,
          deals: [deal],
        );
      } else {
        map[key]!.deals.add(deal);
      }
    }
    return map.values.toList();
  }

  int get _activeFiltersCount {
    int count = 0;
    if (_searchQuery.trim().isNotEmpty) count++;
    if (_selectedMacroCategory != 'Tous') count++;
    if (_selectedCategory != 'Tous') count++;
    if (_selectedQuartier != 'Tous') count++;
    if (_sortOption != FeedSortOption.distance) count++;
    return count;
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedMacroCategory = 'Tous';
      _selectedCategory = 'Tous';
      _selectedQuartier = 'Tous';
      _sortOption = FeedSortOption.distance;
    });
  }

  void _handleBookRequest(DealItem deal) {
    final user = supabase.auth.currentUser;
    if (user == null) {
      widget.onRequireAuth(() => _executeBooking(deal));
    } else {
      _executeBooking(deal);
    }
  }

  void _handleFavoriteToggle(DealItem deal) {
    final user = supabase.auth.currentUser;
    if (user == null) {
      widget.onRequireAuth(() async {
        final added = await FavoritesService.instance.toggleFavorite(deal.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                added ? "Ajouté aux favoris ! ❤️" : "Retiré des favoris",
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      });
    } else {
      FavoritesService.instance.toggleFavorite(deal.id).then((added) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                added ? "Ajouté aux favoris ! ❤️" : "Retiré des favoris",
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      });
    }
  }

  Future<void> _executeBooking(DealItem deal) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final code = (100000 + math.Random().nextInt(900000)).toString();

    try {
      await supabase
          .from('deals')
          .update({'remaining_count': deal.remainingCount - 1})
          .eq('id', deal.id);

      await supabase.from('bookings').insert({
        'deal_id': deal.id,
        'pass_code': code,
        'status': 'reserve',
      });

      final prefs = await SharedPreferences.getInstance();
      final existingJson = prefs.getString('my_pass_codes_${user.id}') ?? '[]';
      final List<dynamic> existing = jsonDecode(existingJson);
      existing.add(code);
      await prefs.setString('my_pass_codes_${user.id}', jsonEncode(existing));

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
      try {
        await supabase
            .from('deals')
            .update({'remaining_count': deal.remainingCount})
            .eq('id', deal.id);
      } catch (_) {}
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Échec de la réservation : $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: BarakaColors.border.withValues(alpha: 0.7)),
          boxShadow: BarakaColors.cardShadow,
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) => setState(() => _searchQuery = val),
          decoration: InputDecoration(
            hintText: "Rechercher (ex: croissant, tajine, fleuriste...)",
            hintStyle: TextStyle(
              color: BarakaColors.textSecondary.withValues(alpha: 0.75),
              fontSize: 13,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.all(8),
              child: Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: BarakaColors.sageLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search_rounded,
                  color: BarakaColors.primary,
                  size: 18,
                ),
              ),
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: Colors.grey,
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMacroCategorySelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: BarakaColors.border.withValues(alpha: 0.8),
                ),
                boxShadow: BarakaColors.cardShadow,
              ),
              child: Row(
                children: [
                  _buildMacroTab(
                    'Tous',
                    'Tout',
                    Icons.auto_awesome_mosaic_rounded,
                  ),
                  _buildMacroTab(
                    'Alimentaire',
                    'Alimentaire',
                    Icons.restaurant_rounded,
                  ),
                  _buildMacroTab(
                    'Services',
                    'Services',
                    Icons.room_service_rounded,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: "Changer d'univers",
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CategoryHubScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: BarakaColors.border.withValues(alpha: 0.8),
                    ),
                    boxShadow: BarakaColors.cardShadow,
                  ),
                  child: const Icon(
                    Icons.dashboard_customize_rounded,
                    size: 19,
                    color: BarakaColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroTab(String key, String title, IconData icon) {
    final isSelected = _selectedMacroCategory == key;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedMacroCategory = key;
            _selectedCategory = 'Tous';
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected ? BarakaColors.primaryGradient : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: BarakaColors.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? Colors.white : BarakaColors.textSecondary,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : BarakaColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    final categories = _currentCategories;
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final rawLabel = cat['label'] as String;
          final icon = cat['icon'] as IconData;
          final isSelected = _selectedCategory == rawLabel;

          String displayLabel = rawLabel;
          if (rawLabel == 'Tous') {
            if (_selectedMacroCategory == 'Alimentaire') {
              displayLabel = "Tout l'alimentaire";
            } else if (_selectedMacroCategory == 'Services') {
              displayLabel = "Tous les services";
            } else {
              displayLabel = "Toutes";
            }
          }

          return ChoiceChip(
            selected: isSelected,
            showCheckmark: false,
            avatar: Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : BarakaColors.primary,
            ),
            label: Text(
              displayLabel,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                fontSize: 12,
                color: isSelected ? Colors.white : BarakaColors.textPrimary,
              ),
            ),
            selectedColor: BarakaColors.primary,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: isSelected ? BarakaColors.primary : BarakaColors.border,
              width: 1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            onSelected: (_) {
              setState(() {
                _selectedCategory = rawLabel;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildFilterAndSortBar(int totalResults) {
    final hasActiveFilters = _activeFiltersCount > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Row(
        children: [
          // Sélecteur de quartier
          Expanded(
            child: PopupMenuButton<String>(
              tooltip: "Sélectionner un quartier",
              initialValue: _selectedQuartier,
              onSelected: (quartier) {
                setState(() => _selectedQuartier = quartier);
              },
              itemBuilder: (context) => _quartiers.map((q) {
                final isQSelected = _selectedQuartier == q;
                return PopupMenuItem<String>(
                  value: q,
                  child: Row(
                    children: [
                      Icon(
                        q == 'Tous' ? Icons.location_city : Icons.place,
                        size: 18,
                        color: isQSelected ? BarakaColors.primary : Colors.grey,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        q == 'Tous' ? 'Tous les quartiers' : q,
                        style: TextStyle(
                          fontWeight:
                              isQSelected ? FontWeight.bold : FontWeight.normal,
                          color: isQSelected
                              ? BarakaColors.primary
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedQuartier != 'Tous'
                      ? BarakaColors.primary.withValues(alpha: 0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _selectedQuartier != 'Tous'
                        ? BarakaColors.primary
                        : BarakaColors.border,
                  ),
                  boxShadow: BarakaColors.cardShadow,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 15,
                      color: _selectedQuartier != 'Tous'
                          ? BarakaColors.primary
                          : BarakaColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _selectedQuartier == 'Tous'
                            ? "Quartier"
                            : _selectedQuartier,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _selectedQuartier != 'Tous'
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: _selectedQuartier != 'Tous'
                              ? BarakaColors.primary
                              : BarakaColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Sélecteur de tri (Distance GPS, Expiration, Récents)
          PopupMenuButton<FeedSortOption>(
            tooltip: "Trier les offres",
            initialValue: _sortOption,
            onSelected: (opt) {
              setState(() => _sortOption = opt);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: FeedSortOption.distance,
                child: Row(
                  children: [
                    Icon(
                      Icons.near_me_rounded,
                      size: 18,
                      color: _sortOption == FeedSortOption.distance
                          ? BarakaColors.primary
                          : Colors.grey,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Distance GPS (plus proche)",
                      style: TextStyle(
                        fontWeight: _sortOption == FeedSortOption.distance
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _sortOption == FeedSortOption.distance
                            ? BarakaColors.primary
                            : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: FeedSortOption.expiration,
                child: Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 18,
                      color: _sortOption == FeedSortOption.expiration
                          ? BarakaColors.terracotta
                          : Colors.grey,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Expire bientôt (urgent)",
                      style: TextStyle(
                        fontWeight: _sortOption == FeedSortOption.expiration
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _sortOption == FeedSortOption.expiration
                            ? BarakaColors.terracotta
                            : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: FeedSortOption.recent,
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 18,
                      color: _sortOption == FeedSortOption.recent
                          ? BarakaColors.primary
                          : Colors.grey,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Plus récents / Pertinents",
                      style: TextStyle(
                        fontWeight: _sortOption == FeedSortOption.recent
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _sortOption == FeedSortOption.recent
                            ? BarakaColors.primary
                            : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: BarakaColors.border),
                boxShadow: BarakaColors.cardShadow,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _sortOption == FeedSortOption.distance
                        ? Icons.near_me_outlined
                        : (_sortOption == FeedSortOption.expiration
                            ? Icons.timer_outlined
                            : Icons.auto_awesome_rounded),
                    size: 15,
                    color: _sortOption == FeedSortOption.expiration
                        ? BarakaColors.terracotta
                        : BarakaColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _sortOption == FeedSortOption.distance
                        ? "Distance"
                        : (_sortOption == FeedSortOption.expiration
                            ? "Expiration"
                            : "Récents"),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: BarakaColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),

          // Bouton reset si filtres actifs
          if (hasActiveFilters) ...[
            const SizedBox(width: 8),
            IconButton(
              tooltip: "Réinitialiser les filtres",
              onPressed: _resetFilters,
              icon: Badge(
                label: Text('$_activeFiltersCount'),
                backgroundColor: BarakaColors.terracotta,
                child: const Icon(
                  Icons.filter_alt_off_rounded,
                  size: 20,
                  color: BarakaColors.terracotta,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultsBanner(int count, {int establishmentCount = 0}) {
    final hasSearch = _searchQuery.trim().isNotEmpty;
    final locationLabel = _selectedQuartier == 'Tous'
        ? "à Marrakech"
        : "à $_selectedQuartier";

    final String bannerLabel;
    if (hasSearch) {
      bannerLabel = establishmentCount > 0
          ? "$count résultat${count > 1 ? 's' : ''} ($establishmentCount commerce${establishmentCount > 1 ? 's' : ''}) pour « ${_searchQuery.trim()} »"
          : "$count résultat${count > 1 ? 's' : ''} pour « ${_searchQuery.trim()} »";
    } else {
      bannerLabel = establishmentCount > 0
          ? "$count panier${count > 1 ? 's' : ''} chez $establishmentCount commerce${establishmentCount > 1 ? 's' : ''} $locationLabel"
          : "$count panier${count > 1 ? 's' : ''} $locationLabel";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    bannerLabel,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: BarakaColors.textSecondary.withValues(alpha: 0.9),
                    ),
                  ),
                ),
                if (hasSearch && count > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: BarakaColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, size: 10, color: BarakaColors.primary),
                        SizedBox(width: 3),
                        Text(
                          "Recherche intelligente",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: BarakaColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_sortOption == FeedSortOption.distance)
            const Row(
              children: [
                Icon(Icons.gps_fixed, size: 11, color: BarakaColors.primary),
                SizedBox(width: 4),
                Text(
                  "Plus proche d'abord",
                  style: TextStyle(
                    fontSize: 11,
                    color: BarakaColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            )
          else if (_sortOption == FeedSortOption.expiration)
            const Row(
              children: [
                Icon(Icons.timer_outlined,
                    size: 11, color: BarakaColors.terracotta),
                SizedBox(width: 4),
                Text(
                  "Urgent d'abord",
                  style: TextStyle(
                    fontSize: 11,
                    color: BarakaColors.terracotta,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            )
          else if (hasSearch)
            const Row(
              children: [
                Icon(Icons.star_rounded, size: 12, color: BarakaColors.primary),
                SizedBox(width: 4),
                Text(
                  "Plus pertinents",
                  style: TextStyle(
                    fontSize: 11,
                    color: BarakaColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: BarakaColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 52,
                color: BarakaColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              "Aucun bon plan trouvé",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: BarakaColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.trim().isNotEmpty
                  ? "Aucune offre ne correspond à « ${_searchQuery.trim()} ».\nMême avec la correction des fautes d'orthographe, aucun résultat n'a été trouvé."
                  : (_activeFiltersCount > 0
                      ? "Aucune offre ne correspond à vos filtres actuels.\nEssayez de modifier votre quartier ou catégorie."
                      : "Revenez un peu plus tard pour découvrir de nouvelles offres."),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: BarakaColors.textSecondary,
                height: 1.4,
              ),
            ),
            if (_activeFiltersCount > 0) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _resetFilters,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text("Réinitialiser tous les filtres"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BarakaColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DealItem>>(
      future: _dealsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            children: [
              _buildMacroCategorySelector(),
              _buildSearchBar(),
              _buildCategorySelector(),
              _buildFilterAndSortBar(0),
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          );
        }
        if (snapshot.hasError) {
          return Column(
            children: [
              _buildMacroCategorySelector(),
              _buildSearchBar(),
              _buildCategorySelector(),
              _buildFilterAndSortBar(0),
              Expanded(
                child: Center(
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
                ),
              ),
            ],
          );
        }

        final allDeals = snapshot.data ?? [];
        final filteredDeals = _applyFiltersAndSort(allDeals);
        final establishmentGroups = _groupDealsByEstablishment(filteredDeals);

        return RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: Column(
            children: [
              _buildMacroCategorySelector(),
              _buildSearchBar(),
              _buildCategorySelector(),
              _buildFilterAndSortBar(filteredDeals.length),
              if (filteredDeals.isNotEmpty)
                _buildResultsBanner(
                  filteredDeals.length,
                  establishmentCount: establishmentGroups.length,
                ),
              Expanded(
                child: establishmentGroups.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: establishmentGroups.length,
                        itemBuilder: (context, i) {
                          final group = establishmentGroups[i];
                          return EstablishmentGroupWidget(
                            group: group,
                            userLat: widget.userLat,
                            userLng: widget.userLng,
                            onSelectDeal: (deal) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DealDetailPage(
                                    deal: deal,
                                    userLat: widget.userLat,
                                    userLng: widget.userLng,
                                    onBook: () => _handleBookRequest(deal),
                                    onToggleFavorite: () =>
                                        _handleFavoriteToggle(deal),
                                  ),
                                ),
                              );
                            },
                            onBookDeal: (deal) => _handleBookRequest(deal),
                            onToggleFavorite: (deal) =>
                                _handleFavoriteToggle(deal),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// -------------------------------------------------------------
// Carte Vitrine Établissement (Case Pro / Commerce)
// -------------------------------------------------------------
class EstablishmentGroupWidget extends StatelessWidget {
  final EstablishmentGroup group;
  final double userLat;
  final double userLng;
  final Function(DealItem) onSelectDeal;
  final Function(DealItem) onBookDeal;
  final Function(DealItem) onToggleFavorite;
  final VoidCallback? onOpenDetail;

  const EstablishmentGroupWidget({
    super.key,
    required this.group,
    required this.userLat,
    required this.userLng,
    required this.onSelectDeal,
    required this.onBookDeal,
    required this.onToggleFavorite,
    this.onOpenDetail,
  });

  double _getDistanceKm() {
    const double r = 6371.0;
    final dLat = (group.latitude - userLat) * (math.pi / 180.0);
    final dLon = (group.longitude - userLng) * (math.pi / 180.0);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(userLat * (math.pi / 180.0)) *
            math.cos(group.latitude * (math.pi / 180.0)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return r * (2 * math.atan2(math.sqrt(a), math.sqrt(1 - a)));
  }

  void _openDetails(BuildContext context) {
    if (onOpenDetail != null) {
      onOpenDetail!();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EstablishmentDetailScreen(
          group: group,
          userLat: userLat,
          userLng: userLng,
          onSelectDeal: onSelectDeal,
          onBookDeal: onBookDeal,
          onToggleFavorite: onToggleFavorite,
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('restau') ||
        c.contains('café') ||
        c.contains('cafe') ||
        c.contains('food') ||
        c.contains('plat')) {
      return Icons.restaurant_rounded;
    }
    if (c.contains('beauté') ||
        c.contains('beaute') ||
        c.contains('spa') ||
        c.contains('bien-être') ||
        c.contains('bien etre') ||
        c.contains('soin') ||
        c.contains('coiff')) {
      return Icons.spa_rounded;
    }
    if (c.contains('héberg') ||
        c.contains('heberg') ||
        c.contains('séjour') ||
        c.contains('sejour') ||
        c.contains('hotel') ||
        c.contains('hôtel') ||
        c.contains('riad')) {
      return Icons.hotel_rounded;
    }
    if (c.contains('activité') ||
        c.contains('activite') ||
        c.contains('loisir')) {
      return Icons.attractions_rounded;
    }
    if (c.contains('mobilité') ||
        c.contains('mobilite') ||
        c.contains('transport') ||
        c.contains('auto') ||
        c.contains('voiture')) {
      return Icons.directions_car_rounded;
    }
    if (c.contains('shopping') ||
        c.contains('service') ||
        c.contains('boutique') ||
        c.contains('mode')) {
      return Icons.shopping_bag_rounded;
    }
    if (c.contains('boulang') || c.contains('pain') || c.contains('patiss')) {
      return Icons.bakery_dining_rounded;
    }
    if (c.contains('épicer') ||
        c.contains('epicer') ||
        c.contains('supermarch')) {
      return Icons.local_grocery_store_rounded;
    }
    if (c.contains('fleur') || c.contains('plante')) {
      return Icons.local_florist_rounded;
    }
    return Icons.storefront_rounded;
  }

  String get _coverImageUrl {
    for (final d in group.deals) {
      if (d.imageUrl.trim().isNotEmpty) return d.imageUrl.trim();
    }
    return '';
  }

  double get _minPrice => group.deals.isEmpty
      ? 0.0
      : group.deals.map((d) => d.discountedPrice).reduce(math.min);

  int get _maxDiscount => group.deals.isEmpty
      ? 0
      : group.deals.map((d) => d.discountPercentage).reduce(math.max);

  Widget _buildThumbnailFallback() {
    return Container(
      width: 108,
      height: 118,
      decoration: const BoxDecoration(
        color: BarakaColors.sageLight,
        borderRadius: BorderRadius.horizontal(left: Radius.circular(18)),
      ),
      child: Center(
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: BarakaColors.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: BarakaColors.primary.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            _getCategoryIcon(group.category),
            size: 22,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final distanceKm = _getDistanceKm();
    final count = group.deals.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: BarakaColors.border.withValues(alpha: 0.9),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openDetails(context),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Vignette Boutique à gauche (108px)
                SizedBox(
                  width: 108,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _coverImageUrl.isNotEmpty
                          ? Image.network(
                              _coverImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildThumbnailFallback(),
                            )
                          : _buildThumbnailFallback(),

                      // Dégradé d'assombrissement
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.15),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.65),
                            ],
                            stops: const [0.0, 0.4, 1.0],
                          ),
                        ),
                      ),

                      // Badge catégorie (Haut Gauche)
                      Positioned(
                        top: 7,
                        left: 7,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Icon(
                            _getCategoryIcon(group.category),
                            size: 13,
                            color: BarakaColors.primary,
                          ),
                        ),
                      ),

                      // Distance GPS (Bas Gauche)
                      Positioned(
                        bottom: 6,
                        left: 7,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "${distanceKm.toStringAsFixed(1)} km",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Fiche d'informations du commerce à droite
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Ligne 1 : Badge partenaire officiel + Remise
                        Row(
                          children: [
                            const Icon(
                              Icons.verified_rounded,
                              size: 13,
                              color: BarakaColors.primary,
                            ),
                            const SizedBox(width: 3),
                            const Text(
                              "COMMERCE PARTENAIRE",
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.2,
                                color: BarakaColors.primary,
                              ),
                            ),
                            const Spacer(),
                            if (_maxDiscount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: BarakaColors.terracottaLight,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  "-$_maxDiscount%",
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: BarakaColors.terracottaDark,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        // Ligne 2 : Nom du commerce
                        Text(
                          group.businessName,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: BarakaColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // Ligne 3 : Quartier / Adresse
                        Row(
                          children: [
                            const Icon(
                              Icons.place_outlined,
                              size: 12,
                              color: BarakaColors.textSecondary,
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                group.location,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: BarakaColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        // Ligne 4 : Prix d'appel & Bouton "Voir les offres (X) →"
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Dès ${_minPrice.toStringAsFixed(0)} MAD",
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: BarakaColors.primary,
                                  ),
                                ),
                                Text(
                                  "🔥 $count offre${count > 1 ? 's' : ''}",
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: count > 1
                                        ? BarakaColors.terracottaDark
                                        : BarakaColors.primaryDark,
                                  ),
                                ),
                              ],
                            ),

                            // Bouton d'accès aux offres
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: BarakaColors.primaryGradient,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: BarakaColors.primary
                                        .withValues(alpha: 0.25),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    count > 1
                                        ? "Voir les offres ($count)"
                                        : "Voir l'offre",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// Élément d'offre à l'intérieur d'un groupe d'établissement
// -------------------------------------------------------------
class _GroupedDealItemWidget extends StatefulWidget {
  final DealItem deal;
  final int dealIndex;
  final int totalDeals;
  final VoidCallback onTap;
  final VoidCallback onBook;
  final VoidCallback onToggleFavorite;

  const _GroupedDealItemWidget({
    required this.deal,
    required this.dealIndex,
    required this.totalDeals,
    required this.onTap,
    required this.onBook,
    required this.onToggleFavorite,
  });

  @override
  State<_GroupedDealItemWidget> createState() => _GroupedDealItemWidgetState();
}

class _GroupedDealItemWidgetState extends State<_GroupedDealItemWidget> {
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

  @override
  Widget build(BuildContext context) {
    final isExpired = _timeLeft.inSeconds <= 0;
    final h = _timeLeft.inHours.toString().padLeft(2, '0');
    final m = (_timeLeft.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_timeLeft.inSeconds % 60).toString().padLeft(2, '0');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge "Offre X sur Y" si plusieurs offres
            if (widget.totalDeals > 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: BarakaColors.terracottaLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.local_offer_outlined,
                            size: 12,
                            color: BarakaColors.terracottaDark,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Offre ${widget.dealIndex + 1} sur ${widget.totalDeals}",
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: BarakaColors.terracottaDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: BarakaColors.sageLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.deal.category,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: BarakaColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Zone Image avec superpositions
            Padding(
              padding: EdgeInsets.fromLTRB(
                14,
                widget.totalDeals > 1 ? 0 : 12,
                14,
                0,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    Image.network(
                      widget.deal.imageUrl,
                      height: widget.totalDeals > 1 ? 155 : 170,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: widget.totalDeals > 1 ? 155 : 170,
                        color: BarakaColors.sageLight,
                        child: const Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 44,
                            color: BarakaColors.primaryLight,
                          ),
                        ),
                      ),
                    ),

                    // Dégradé sombre au bas de l'image
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.1),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.65),
                            ],
                            stops: const [0.0, 0.45, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // Badge Réduction en haut à gauche
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4.5,
                        ),
                        decoration: BoxDecoration(
                          gradient: BarakaColors.terracottaGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: BarakaColors.terracotta
                                  .withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.bolt_rounded,
                              color: Colors.white,
                              size: 13,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              "-${widget.deal.discountPercentage}%",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bouton Favoris en haut à droite
                    Positioned(
                      top: 10,
                      right: 10,
                      child: ValueListenableBuilder<Set<String>>(
                        valueListenable:
                            FavoritesService.instance.favoritesNotifier,
                        builder: (context, favs, _) {
                          final isFav = favs.contains(widget.deal.id);
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: widget.onToggleFavorite,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(
                                    isFav
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: isFav
                                        ? BarakaColors.terracotta
                                        : BarakaColors.textPrimary,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Décompte de temps en bas à gauche
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: isExpired
                              ? BarakaColors.terracotta.withValues(alpha: 0.9)
                              : Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 12,
                              color: Colors.white.withValues(alpha: 0.95),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isExpired ? "Expiré" : "$h:$m:$s",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Contenu textuel et prix
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre du panier
                  Text(
                    widget.deal.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: BarakaColors.textPrimary,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),

                  // Ligne de Prix et Bouton Réserver
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            "${widget.deal.discountedPrice.toStringAsFixed(0)} MAD",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              color: BarakaColors.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "${widget.deal.originalPrice.toStringAsFixed(0)} MAD",
                            style: TextStyle(
                              fontSize: 13,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: Colors.grey.shade400,
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      // Colonne : Quantité restante au-dessus + Bouton Réserver
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Quantité restante affichée au-dessus du bouton
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: widget.deal.remainingCount <= 2
                                      ? BarakaColors.terracotta
                                      : BarakaColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.deal.remainingCount > 0
                                    ? "${widget.deal.remainingCount} restant${widget.deal.remainingCount > 1 ? 's' : ''}"
                                    : "Épuisé",
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: widget.deal.remainingCount <= 2
                                      ? BarakaColors.terracotta
                                      : BarakaColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),

                          // Bouton Réserver
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: (!isExpired &&
                                      widget.deal.remainingCount > 0)
                                  ? BarakaColors.primaryGradient
                                  : null,
                              color: (!isExpired &&
                                      widget.deal.remainingCount > 0)
                                  ? null
                                  : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: (!isExpired &&
                                      widget.deal.remainingCount > 0)
                                  ? [
                                      BoxShadow(
                                        color: BarakaColors.primary
                                            .withValues(alpha: 0.28),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: (!isExpired &&
                                        widget.deal.remainingCount > 0)
                                    ? widget.onBook
                                    : null,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        (!isExpired &&
                                                widget.deal.remainingCount > 0)
                                            ? Icons.shopping_bag_outlined
                                            : Icons.block_rounded,
                                        size: 15,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        isExpired
                                            ? "Expiré"
                                            : (widget.deal.remainingCount > 0
                                                ? "Réserver"
                                                : "Épuisé"),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
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
// Carte Deal
// -------------------------------------------------------------
class DealCardWidget extends StatefulWidget {
  final DealItem deal;
  final double userLat;
  final double userLng;
  final VoidCallback onTap;
  final VoidCallback onBook;
  final VoidCallback onToggleFavorite;

  const DealCardWidget({
    super.key,
    required this.deal,
    required this.userLat,
    required this.userLng,
    required this.onTap,
    required this.onBook,
    required this.onToggleFavorite,
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

  IconData _getCategoryIcon(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('restau') ||
        c.contains('café') ||
        c.contains('cafe') ||
        c.contains('food') ||
        c.contains('plat')) {
      return Icons.restaurant_rounded;
    }
    if (c.contains('beauté') ||
        c.contains('beaute') ||
        c.contains('spa') ||
        c.contains('bien-être') ||
        c.contains('bien etre') ||
        c.contains('soin') ||
        c.contains('coiff')) {
      return Icons.spa_rounded;
    }
    if (c.contains('héberg') ||
        c.contains('heberg') ||
        c.contains('séjour') ||
        c.contains('sejour') ||
        c.contains('hotel') ||
        c.contains('hôtel') ||
        c.contains('riad')) {
      return Icons.hotel_rounded;
    }
    if (c.contains('activité') ||
        c.contains('activite') ||
        c.contains('loisir')) {
      return Icons.attractions_rounded;
    }
    if (c.contains('mobilité') ||
        c.contains('mobilite') ||
        c.contains('transport') ||
        c.contains('auto') ||
        c.contains('voiture')) {
      return Icons.directions_car_rounded;
    }
    if (c.contains('shopping') ||
        c.contains('service') ||
        c.contains('boutique') ||
        c.contains('mode')) {
      return Icons.shopping_bag_rounded;
    }
    if (c.contains('boulang') || c.contains('pain') || c.contains('patiss')) {
      return Icons.bakery_dining_rounded;
    }
    if (c.contains('épicer') ||
        c.contains('epicer') ||
        c.contains('supermarch')) {
      return Icons.local_grocery_store_rounded;
    }
    if (c.contains('fleur') || c.contains('plante')) {
      return Icons.local_florist_rounded;
    }
    return Icons.local_offer_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = _timeLeft.inSeconds <= 0;
    final h = _timeLeft.inHours.toString().padLeft(2, '0');
    final m = (_timeLeft.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_timeLeft.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: BarakaColors.border.withValues(alpha: 0.7)),
        boxShadow: BarakaColors.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Zone Image avec superpositions modernes
              Stack(
                children: [
                  Image.network(
                    widget.deal.imageUrl,
                    height: 175,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 175,
                      color: BarakaColors.sageLight,
                      child: const Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 44,
                          color: BarakaColors.primaryLight,
                        ),
                      ),
                    ),
                  ),

                  // Dégradé sombre au bas de l'image pour contraster les puces
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.1),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.65),
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Badge Réduction en haut à gauche
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        gradient: BarakaColors.terracottaGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: BarakaColors.terracotta.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.bolt_rounded,
                            size: 13,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            "-${widget.deal.discountPercentage}%",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bouton Favoris en haut à droite (verre dépoli)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: ValueListenableBuilder<Set<String>>(
                      valueListenable:
                          FavoritesService.instance.favoritesNotifier,
                      builder: (context, favs, _) {
                        final isFav = favs.contains(widget.deal.id);
                        return Material(
                          color: Colors.white.withValues(alpha: 0.94),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: widget.onToggleFavorite,
                            child: Container(
                              padding: const EdgeInsets.all(7.5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                isFav
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: isFav
                                    ? BarakaColors.terracotta
                                    : BarakaColors.textPrimary,
                                size: 19,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Décompte de temps en bas à gauche de l'image
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isExpired
                            ? BarakaColors.terracotta.withValues(alpha: 0.9)
                            : Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 13,
                            color: Colors.white.withValues(alpha: 0.95),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isExpired ? "Expiré" : "$h:$m:$s",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Distance GPS en bas à droite de l'image
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.near_me_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            "${_getDistanceKm().toStringAsFixed(1)} km",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Contenu textuel et prix
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ligne catégorie et localisation
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: BarakaColors.sageLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getCategoryIcon(widget.deal.category),
                                size: 12,
                                color: BarakaColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.deal.category,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: BarakaColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF6F5F2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.place_outlined,
                                  size: 12,
                                  color: BarakaColors.textSecondary,
                                ),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    widget.deal.location,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: BarakaColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Nom du commerce
                    Text(
                      widget.deal.businessName.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: BarakaColors.textSecondary.withValues(alpha: 0.85),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),

                    // Titre du panier
                    Text(
                      widget.deal.title,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: BarakaColors.textPrimary,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),

                    // Ligne de Prix et Bouton Réserver
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              "${widget.deal.discountedPrice.toStringAsFixed(0)} MAD",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                color: BarakaColors.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "${widget.deal.originalPrice.toStringAsFixed(0)} MAD",
                              style: TextStyle(
                                fontSize: 13,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: Colors.grey.shade400,
                                color: Colors.grey.shade400,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        // Colonne : Quantité restante au-dessus + Bouton Réserver
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Quantité restante affichée au-dessus du bouton
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: widget.deal.remainingCount <= 2
                                        ? BarakaColors.terracotta
                                        : BarakaColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.deal.remainingCount > 0
                                      ? "${widget.deal.remainingCount} restant${widget.deal.remainingCount > 1 ? 's' : ''}"
                                      : "Épuisé",
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: widget.deal.remainingCount <= 2
                                        ? BarakaColors.terracotta
                                        : BarakaColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),

                            // Bouton Réserver
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: widget.deal.remainingCount > 0
                                    ? BarakaColors.primaryGradient
                                    : null,
                                color: widget.deal.remainingCount > 0
                                    ? null
                                    : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: widget.deal.remainingCount > 0
                                    ? [
                                        BoxShadow(
                                          color: BarakaColors.primary
                                              .withValues(alpha: 0.28),
                                          blurRadius: 10,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: widget.deal.remainingCount > 0
                                      ? widget.onBook
                                      : null,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 9,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          widget.deal.remainingCount > 0
                                              ? Icons.shopping_bag_outlined
                                              : Icons.block_rounded,
                                          size: 15,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          widget.deal.remainingCount > 0
                                              ? "Réserver"
                                              : "Épuisé",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
// Écran Détails d'un Deal (Accessible à tous)
// -------------------------------------------------------------
class DealDetailPage extends StatelessWidget {
  final DealItem deal;
  final double userLat;
  final double userLng;
  final VoidCallback onBook;
  final VoidCallback onToggleFavorite;

  const DealDetailPage({
    super.key,
    required this.deal,
    required this.userLat,
    required this.userLng,
    required this.onBook,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(deal.businessName),
        actions: [
          ValueListenableBuilder<Set<String>>(
            valueListenable: FavoritesService.instance.favoritesNotifier,
            builder: (context, favs, _) {
              final isFav = favs.contains(deal.id);
              return IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color:
                      isFav ? BarakaColors.terracotta : BarakaColors.textPrimary,
                ),
                tooltip: isFav ? "Retirer des favoris" : "Ajouter aux favoris",
                onPressed: onToggleFavorite,
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
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
                          color: BarakaColors.terracotta,
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
                              color: BarakaColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Indicateur de quantité restante placé au-dessus du bouton
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: deal.remainingCount <= 2
                                  ? BarakaColors.terracotta
                                  : BarakaColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            deal.remainingCount > 0
                                ? "${deal.remainingCount} restant${deal.remainingCount > 1 ? 's' : ''}"
                                : "Épuisé",
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: deal.remainingCount <= 2
                                  ? BarakaColors.terracotta
                                  : BarakaColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      ValueListenableBuilder<Set<String>>(
                        valueListenable:
                            FavoritesService.instance.favoritesNotifier,
                        builder: (context, favs, _) {
                          final isFav = favs.contains(deal.id);
                          return OutlinedButton.icon(
                            onPressed: onToggleFavorite,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isFav
                                  ? BarakaColors.terracotta
                                  : Colors.black87,
                              side: BorderSide(
                                color: isFav
                                  ? BarakaColors.terracotta
                                  : Colors.grey.shade400,
                                width: 1.5,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              size: 20,
                            ),
                            label: Text(
                              isFav ? "Favori" : "Enregistrer",
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: deal.remainingCount > 0
                              ? () {
                                  Navigator.pop(context);
                                  onBook();
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: BarakaColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Réserver ce bon plan",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
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
              const BarakaLogo(size: 140, showTagline: true),
              const SizedBox(height: 18),
              Text(
                _isSignUp
                    ? "Créez votre compte pour commencer"
                    : "Connectez-vous pour continuer",
                textAlign: TextAlign.center,
                style: const TextStyle(color: BarakaColors.textSecondary),
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
                        selectedColor: BarakaColors.sage,
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
                        selectedColor: BarakaColors.sage,
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
                    backgroundColor: BarakaColors.primary,
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
                style: TextButton.styleFrom(
                  foregroundColor: BarakaColors.terracotta,
                ),
                child: Text(
                  _isSignUp
                      ? "Déjà un compte ? Se connecter"
                      : "Nouveau ? Créer un compte",
                  style: const TextStyle(fontWeight: FontWeight.bold),
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
      backgroundColor: BarakaColors.primary,
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
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: BarakaColors.textSecondary,
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
                        color: BarakaColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    QrImageView(
                      data: payload,
                      version: QrVersions.auto,
                      size: 190.0,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: BarakaColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Code secret à présenter sur place :",
                      style: TextStyle(color: BarakaColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      code,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 6,
                        color: BarakaColors.terracotta,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "À régler sur place : ${deal.discountedPrice.toStringAsFixed(0)} MAD",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: BarakaColors.primary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Notification de sauvegarde automatique
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: BarakaColors.sage,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.cloud_done, color: BarakaColors.primary, size: 22),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Pass sauvegardé automatiquement dans l'onglet 'Mes Pass' tant qu'il n'est pas utilisé ou expiré.",
                              style: TextStyle(
                                fontSize: 12,
                                color: BarakaColors.primaryDark,
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
                            backgroundColor: BarakaColors.primary,
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
  String _category = 'Restauration & Cafés';
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
          .add(const Duration(days: 3))
          .toIso8601String();

      await supabase.from('deals').insert({
        'title': title,
        'business_name': business,
        'original_price': original,
        'discounted_price': discounted,
        'remaining_count': stock,
        'location': _locCtrl.text.trim(),
        'category': _category,
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
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(
              labelText: "Catégorie",
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'Restauration & Cafés',
                child: Text('🍽️ Restauration & Cafés'),
              ),
              DropdownMenuItem(
                value: 'Beauté & Bien-être',
                child: Text('💆 Beauté & Bien-être'),
              ),
              DropdownMenuItem(
                value: 'Hébergement & Séjours',
                child: Text('🏨 Hébergement & Séjours'),
              ),
              DropdownMenuItem(
                value: 'Activités & Loisirs',
                child: Text('🎡 Activités & Loisirs'),
              ),
              DropdownMenuItem(
                value: 'Mobilité & Transports',
                child: Text('🚗 Mobilité & Transports'),
              ),
              DropdownMenuItem(
                value: 'Shopping & Services',
                child: Text('🛍️ Shopping & Services'),
              ),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _category = val);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _locCtrl,
            decoration: const InputDecoration(
              labelText: "Quartier (ex: Guéliz, Médina...)",
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
                backgroundColor: BarakaColors.primary,
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
