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
                  // Badge Réduction
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
                          const Icon(Icons.bolt_rounded, size: 13, color: Colors.white),
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
                  // Bouton Retirer des favoris
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.94),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: widget.onRemoveFavorite,
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
                          child: const Icon(
                            Icons.favorite_rounded,
                            color: BarakaColors.terracotta,
                            size: 19,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Timer
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
                            color: Colors.white.withValues(alpha: 0.95),
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTimer(_timeLeft),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11.5,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Distance
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
                          const Icon(Icons.near_me_rounded, size: 12, color: Colors.white),
                          const SizedBox(width: 3),
                          Text(
                            "${widget.distanceKm.toStringAsFixed(1)} km",
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.deal.businessName.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: BarakaColors.textSecondary.withValues(alpha: 0.85),
                        letterSpacing: 0.6,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: (!isExpired && widget.deal.remainingCount > 0)
                                ? BarakaColors.primaryGradient
                                : null,
                            color: (!isExpired && widget.deal.remainingCount > 0)
                                ? null
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: (!isExpired && widget.deal.remainingCount > 0)
                                ? [
                                    BoxShadow(
                                      color: BarakaColors.primary.withValues(alpha: 0.28),
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
                              onTap: (!isExpired && widget.deal.remainingCount > 0)
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
                                      (!isExpired && widget.deal.remainingCount > 0)
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
                                              ? "Bloquer (${widget.deal.remainingCount})"
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
