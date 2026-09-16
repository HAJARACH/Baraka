import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/deal.dart';
import '../services/favorites_service.dart';
import '../theme/app_theme.dart';

class FavoritesScreen extends StatefulWidget {
  final double userLat;
  final double userLng;
  final VoidCallback onGoToFeed;
  final void Function(VoidCallback action) onRequireAuth;
  final void Function(Deal deal) onBookDeal;
  final void Function(Deal deal) onOpenDealDetail;

  const FavoritesScreen({
    super.key,
    required this.userLat,
    required this.userLng,
    required this.onGoToFeed,
    required this.onRequireAuth,
    required this.onBookDeal,
    required this.onOpenDealDetail,
  });

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final supabase = Supabase.instance.client;
  Future<List<Deal>>? _favDealsFuture;
  VoidCallback? _favListener;

  @override
  void initState() {
    super.initState();
    _refresh();

    _favListener = () {
      if (mounted) _refresh();
    };
    FavoritesService.instance.favoritesNotifier.addListener(_favListener!);
  }

  @override
  void dispose() {
    if (_favListener != null) {
      FavoritesService.instance.favoritesNotifier.removeListener(_favListener!);
    }
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _favDealsFuture = _fetchFavoriteDeals();
    });
  }

  Future<List<Deal>> _fetchFavoriteDeals() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    final favIds = FavoritesService.instance.favoritesNotifier.value;
    if (favIds.isEmpty) return [];

    try {
      final res = await supabase
          .from('deals')
          .select()
          .inFilter('id', favIds.toList());

      final list = (res as List)
          .map((item) => Deal.fromMap(item as Map<String, dynamic>))
          .toList();

      return list;
    } catch (e) {
      debugPrint("Erreur récupération favoris : $e");
      return [];
    }
  }

  double _getDistanceKm(double lat, double lng) {
    const double r = 6371.0;
    final dLat = (lat - widget.userLat) * (math.pi / 180.0);
    final dLon = (lng - widget.userLng) * (math.pi / 180.0);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(widget.userLat * (math.pi / 180.0)) *
            math.cos(lat * (math.pi / 180.0)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return r * (2 * math.atan2(math.sqrt(a), math.sqrt(1 - a)));
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            "Mes Favoris",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
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
                  padding: const EdgeInsets.all(22),
                  decoration: const BoxDecoration(
                    color: BarakaColors.terracottaLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_border,
                    size: 60,
                    color: BarakaColors.terracotta,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Connectez-vous pour vos favoris",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: BarakaColors.textPrimary),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Enregistrez tous vos coups de cœur sans forcément les bloquer pour les retrouver en un coup d'œil à tout moment.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: BarakaColors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => widget.onRequireAuth(() => _refresh()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BarakaColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.login),
                  label: const Text(
                    "Se connecter / S'inscrire",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: BarakaColors.background,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.favorite, color: BarakaColors.terracotta),
            SizedBox(width: 8),
            Text(
              "Mes Favoris",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: BarakaColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Actualiser",
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<List<Deal>>(
        future: _favDealsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: BarakaColors.primary),
            );
          }

          final deals = snapshot.data ?? [];

          if (deals.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.favorite_outline,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      "Aucun coup de cœur pour l'instant",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Cliquez sur le cœur d'une offre pour la sauvegarder sans la bloquer et la retrouver facilement ici.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: widget.onGoToFeed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BarakaColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.local_offer_outlined),
                      label: const Text(
                        "Explorer les bons plans",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: deals.length,
              itemBuilder: (context, index) {
                final deal = deals[index];
                final distanceKm = _getDistanceKm(deal.latitude, deal.longitude);

                return _FavoriteDealCard(
                  deal: deal,
                  distanceKm: distanceKm,
                  onTap: () => widget.onOpenDealDetail(deal),
                  onBook: () => widget.onBookDeal(deal),
                  onRemoveFavorite: () async {
                    await FavoritesService.instance.toggleFavorite(deal.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Retiré des favoris"),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _FavoriteDealCard extends StatefulWidget {
  final Deal deal;
  final double distanceKm;
  final VoidCallback onTap;
  final VoidCallback onBook;
  final VoidCallback onRemoveFavorite;

  const _FavoriteDealCard({
    required this.deal,
    required this.distanceKm,
    required this.onTap,
    required this.onBook,
    required this.onRemoveFavorite,
  });

  @override
  State<_FavoriteDealCard> createState() => _FavoriteDealCardState();
}

class _FavoriteDealCardState extends State<_FavoriteDealCard> {
  Timer? _timer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _updateRemaining();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateRemaining() {
    final diff = widget.deal.expiresAt.difference(DateTime.now());
    setState(() {
      _timeLeft = diff.isNegative ? Duration.zero : diff;
    });
  }

  String _formatTimer(Duration d) {
    if (d.inSeconds <= 0) return "Expiré";
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$h:$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = _timeLeft.inSeconds <= 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                // Badge pourcentage
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: BarakaColors.terracotta,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "-${widget.deal.discountPercentage}%",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                // Timer
                Positioned(
                  top: 12,
                  right: 56,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isExpired
                          ? BarakaColors.terracotta
                          : Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          color: Colors.white,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTimer(_timeLeft),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Bouton retirer des favoris (cœur terracotta rempli)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.92),
                    shape: const CircleBorder(),
                    elevation: 2,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: widget.onRemoveFavorite,
                      child: const Padding(
                        padding: EdgeInsets.all(7),
                        child: Icon(
                          Icons.favorite,
                          color: BarakaColors.terracotta,
                          size: 20,
                        ),
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
                        "${widget.distanceKm.toStringAsFixed(1)} km",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: BarakaColors.primary,
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
                              color: BarakaColors.primary,
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
                        onPressed: (!isExpired && widget.deal.remainingCount > 0)
                            ? widget.onBook
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BarakaColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          isExpired
                              ? "Expiré"
                              : "Bloquer (${widget.deal.remainingCount})",
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
