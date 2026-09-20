import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../main.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';

/// Nouvelle fenêtre dédiée affichant les informations d'un établissement partenaire
/// ainsi que la liste complète de tous ses paniers / offres anti-gaspi.
class EstablishmentDetailScreen extends StatelessWidget {
  final EstablishmentGroup group;
  final double userLat;
  final double userLng;
  final Function(DealItem) onSelectDeal;
  final Function(DealItem) onBookDeal;
  final Function(DealItem) onToggleFavorite;

  const EstablishmentDetailScreen({
    super.key,
    required this.group,
    required this.userLat,
    required this.userLng,
    required this.onSelectDeal,
    required this.onBookDeal,
    required this.onToggleFavorite,
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

  IconData _getCategoryIcon(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('boulang') || c.contains('pain') || c.contains('patiss')) {
      return Icons.bakery_dining_rounded;
    }
    if (c.contains('restau') || c.contains('food') || c.contains('plat')) {
      return Icons.restaurant_rounded;
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

  int get _maxDiscount => group.deals.isEmpty
      ? 0
      : group.deals.map((d) => d.discountPercentage).reduce(math.max);

  double get _minPrice => group.deals.isEmpty
      ? 0.0
      : group.deals.map((d) => d.discountedPrice).reduce(math.min);

  Widget _buildCoverFallback() {
    return Container(
      height: 180,
      width: double.infinity,
      color: BarakaColors.sageLight,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                gradient: BarakaColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: BarakaColors.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                _getCategoryIcon(group.category),
                size: 26,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              group.businessName,
              style: const TextStyle(
                color: BarakaColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final distanceKm = _getDistanceKm();
    final count = group.deals.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          group.businessName,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 17,
            color: BarakaColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: BarakaColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
          tooltip: "Retour aux commerces",
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          physics: const BouncingScrollPhysics(),
          children: [
            // Fiche Récapitulative du Commerce (En-tête de la boutique)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: BarakaColors.border.withValues(alpha: 0.85),
                ),
                boxShadow: BarakaColors.cardShadow,
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photo de devanture avec badges
                  Stack(
                    children: [
                      _coverImageUrl.isNotEmpty
                          ? Image.network(
                              _coverImageUrl,
                              height: 170,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildCoverFallback(),
                            )
                          : _buildCoverFallback(),

                      // Dégradé sombre
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.25),
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.65),
                              ],
                              stops: const [0.0, 0.45, 1.0],
                            ),
                          ),
                        ),
                      ),

                      // Badge officiel partenaire
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4.5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.verified_rounded,
                                size: 13,
                                color: BarakaColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                group.category.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                  color: BarakaColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Badge Nombre d'offres
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            gradient: count > 1
                                ? BarakaColors.terracottaGradient
                                : null,
                            color: count > 1
                                ? null
                                : Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            count > 1 ? "🔥 $count offres" : "1 offre active",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: count > 1
                                  ? Colors.white
                                  : BarakaColors.primaryDark,
                            ),
                          ),
                        ),
                      ),

                      // Distance GPS
                      Positioned(
                        bottom: 10,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.place_outlined,
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                "${distanceKm.toStringAsFixed(1)} km",
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Informations du commerce
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.businessName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                            color: BarakaColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 15,
                              color: BarakaColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                group.location,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: BarakaColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Bannière de confiance
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: BarakaColors.sageLight.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  BarakaColors.primary.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.eco_rounded,
                                size: 17,
                                color: BarakaColors.primary,
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  "Partenaire anti-gaspi • Paniers dès ${_minPrice.toStringAsFixed(0)} MAD${_maxDiscount > 0 ? ' (jusqu\'à -$_maxDiscount%)' : ''}",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: BarakaColors.primaryDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // En-tête de section "Offres disponibles"
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: BarakaColors.terracottaLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      size: 15,
                      color: BarakaColors.terracottaDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Offres disponibles (${group.deals.length})",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: BarakaColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // Liste des deals sous forme de cartes complètes
            for (final deal in group.deals)
              DealCardWidget(
                deal: deal,
                userLat: userLat,
                userLng: userLng,
                onTap: () => onSelectDeal(deal),
                onBook: () => onBookDeal(deal),
                onToggleFavorite: () => onToggleFavorite(deal),
              ),
          ],
        ),
      ),
    );
  }
}
