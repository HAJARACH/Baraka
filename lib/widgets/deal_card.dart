import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/deal.dart';
import '../services/favorites_service.dart';
import '../theme/app_theme.dart';

class DealCard extends StatefulWidget {
  final Deal deal;
  final VoidCallback onTap;
  final double userLat;
  final double userLng;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onBook;

  const DealCard({
    super.key,
    required this.deal,
    required this.onTap,
    required this.userLat,
    required this.userLng,
    this.onToggleFavorite,
    this.onBook,
  });

  @override
  State<DealCard> createState() => _DealCardState();
}

class _DealCardState extends State<DealCard> {
  Timer? _timer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemainingTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _updateRemainingTime();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateRemainingTime() {
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

  double _calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371.0;
    final dLat = (lat2 - lat1) * (math.pi / 180.0);
    final dLon = (lon2 - lon1) * (math.pi / 180.0);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * (math.pi / 180.0)) *
            math.cos(lat2 * (math.pi / 180.0)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  @override
  Widget build(BuildContext context) {
    final distanceKm = _calculateDistanceKm(
      widget.userLat,
      widget.userLng,
      widget.deal.latitude,
      widget.deal.longitude,
    );
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
          onTap: isExpired ? null : widget.onTap,
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
                        child: Icon(Icons.image_outlined, size: 44, color: BarakaColors.primaryLight),
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
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                  Positioned(
                    top: 10,
                    right: 10,
                    child: ValueListenableBuilder<Set<String>>(
                      valueListenable: FavoritesService.instance.favoritesNotifier,
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
                                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                color: isFav ? BarakaColors.terracotta : BarakaColors.textPrimary,
                                size: 19,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
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
                          Icon(Icons.timer_outlined, color: Colors.white.withValues(alpha: 0.95), size: 13),
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
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                            "${distanceKm.toStringAsFixed(1)} km",
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
                                color: Colors.grey.shade400,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: Colors.grey.shade400,
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
                                      ? (widget.onBook ?? widget.onTap)
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
      ),
    );
  }
}