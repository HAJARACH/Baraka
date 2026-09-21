import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../main.dart';
import '../models/category_hierarchy.dart';
import '../services/favorites_service.dart';
import '../theme/app_theme.dart';

/// Page d'établissement et de ses offres inspirée de l'expérience Glovo,
/// adaptée au concept anti-gaspillage de Baraka.
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
    return BarakaCategoryHierarchy.getIcon(cat);
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

  void _showStoreInfoModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    gradient: BarakaColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getCategoryIcon(group.category),
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.businessName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: BarakaColors.textPrimary,
                        ),
                      ),
                      Text(
                        "${group.category} • Partenaire Baraka",
                        style: const TextStyle(
                          fontSize: 12,
                          color: BarakaColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.place_outlined,
                    size: 18, color: BarakaColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    group.location,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: BarakaColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Row(
              children: [
                Icon(Icons.schedule_rounded,
                    size: 18, color: BarakaColors.primary),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Créneaux de collecte : Voir sur chaque panier",
                    style: TextStyle(
                      fontSize: 13,
                      color: BarakaColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: BarakaColors.sageLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.eco_rounded,
                      size: 20, color: BarakaColors.primary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Ce commerce s'engage activement contre le gaspillage alimentaire à Marrakech en revalorisant ses invendus.",
                      style: TextStyle(
                        fontSize: 11.5,
                        color: BarakaColors.primaryDark,
                        fontWeight: FontWeight.w600,
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
              width: 50,
              height: 50,
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
                size: 24,
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
      backgroundColor: const Color(0xFFFBFBF9),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. En-tête Magasin façon Glovo (SliverAppBar avec photo de couverture et bouton retour flottant)
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: BarakaColors.textPrimary,
            elevation: 0.5,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.92),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 17,
                    color: BarakaColors.textPrimary,
                  ),
                  tooltip: "Retour aux commerces",
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _coverImageUrl.isNotEmpty
                      ? Image.network(
                          _coverImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildCoverFallback(),
                        )
                      : _buildCoverFallback(),
                  // Dégradé Glovo élégant
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.35),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.45),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                  // Badge distance au bas de la photo
                  Positioned(
                    bottom: 12,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
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
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
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

          // 2. Fiche d'identité du commerce (Style Store Profile Glovo)
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom du commerce
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          group.businessName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: BarakaColors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.info_outline_rounded,
                          size: 21,
                          color: BarakaColors.primary,
                        ),
                        tooltip: "Infos sur l'établissement",
                        onPressed: () => _showStoreInfoModal(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Ligne de badges et métadonnées façon Glovo
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Badge Note / Confiance Glovo
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: BarakaColors.sageLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.thumb_up_rounded,
                              size: 12,
                              color: BarakaColors.primary,
                            ),
                            SizedBox(width: 4),
                            Text(
                              "98% (Partenaire vérifié)",
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: BarakaColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Spécialité
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F3EE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          group.category,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: BarakaColors.textPrimary,
                          ),
                        ),
                      ),

                      // Quartier
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: BarakaColors.textSecondary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            group.location,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: BarakaColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Bandeau Promotionnel / Anti-Gaspi Glovo
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: BarakaColors.sageLight.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: BarakaColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.eco_rounded,
                          size: 17,
                          color: BarakaColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Paniers anti-gaspi dès ${_minPrice.toStringAsFixed(0)} MAD${_maxDiscount > 0 ? ' • Jusqu\'à -$_maxDiscount% d\'économie' : ''}",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
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
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 10),
          ),

          // 3. Titre de la section des offres
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      gradient: BarakaColors.terracottaGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      size: 15,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Offres disponibles ($count)",
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w900,
                      color: BarakaColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Liste des offres sous forme de cartes articles horizontales (Style Glovo)
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final deal = group.deals[index];
                  return _GlovoDealItemWidget(
                    deal: deal,
                    userLat: userLat,
                    userLng: userLng,
                    onTap: () => onSelectDeal(deal),
                    onBook: () => onBookDeal(deal),
                    onToggleFavorite: () => onToggleFavorite(deal),
                  );
                },
                childCount: count,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte d'offre horizontale façon article Glovo,
/// optimisée pour la clarté et l'action anti-gaspi.
class _GlovoDealItemWidget extends StatefulWidget {
  final DealItem deal;
  final double userLat;
  final double userLng;
  final VoidCallback onTap;
  final VoidCallback onBook;
  final VoidCallback onToggleFavorite;

  const _GlovoDealItemWidget({
    required this.deal,
    required this.userLat,
    required this.userLng,
    required this.onTap,
    required this.onBook,
    required this.onToggleFavorite,
  });

  @override
  State<_GlovoDealItemWidget> createState() => _GlovoDealItemWidgetState();
}

class _GlovoDealItemWidgetState extends State<_GlovoDealItemWidget> {
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: BarakaColors.border.withValues(alpha: 0.8),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Colonne Infos (Gauche)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titre du panier
                      Text(
                        widget.deal.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          color: BarakaColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      Text(
                        "${widget.deal.category} • Panier surprise anti-gaspi",
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: BarakaColors.textSecondary,
                          height: 1.25,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Badge compte à rebours & stock
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: isExpired
                                  ? Colors.grey.shade200
                                  : BarakaColors.terracottaLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.timer_outlined,
                                  size: 11,
                                  color: isExpired
                                      ? Colors.grey
                                      : BarakaColors.terracottaDark,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  isExpired ? "Expiré" : "$h:$m:$s",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: isExpired
                                        ? Colors.grey
                                        : BarakaColors.terracottaDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: BarakaColors.sageLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "Reste : ${widget.deal.remainingCount}",
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: BarakaColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Ligne des Prix
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            "${widget.deal.discountedPrice.toStringAsFixed(0)} MAD",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: BarakaColors.primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "${widget.deal.originalPrice.toStringAsFixed(0)} MAD",
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: BarakaColors.textSecondary,
                              decoration: TextDecoration.lineThrough,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Vignette Photo Carrée & Bouton Réserver (Droite)
                Column(
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: widget.deal.imageUrl.isNotEmpty
                              ? Image.network(
                                  widget.deal.imageUrl,
                                  width: 95,
                                  height: 95,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    width: 95,
                                    height: 95,
                                    color: BarakaColors.sageLight,
                                    child: const Icon(
                                      Icons.fastfood_outlined,
                                      size: 30,
                                      color: BarakaColors.primaryLight,
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 95,
                                  height: 95,
                                  color: BarakaColors.sageLight,
                                  child: const Icon(
                                    Icons.fastfood_outlined,
                                    size: 30,
                                    color: BarakaColors.primaryLight,
                                  ),
                                ),
                        ),
                        // Badge Remise en haut à gauche de la vignette
                        if (widget.deal.discountPercentage > 0)
                          Positioned(
                            top: 5,
                            left: 5,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                gradient: BarakaColors.terracottaGradient,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "-${widget.deal.discountPercentage}%",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        // Bouton favori en haut à droite
                        Positioned(
                          top: 2,
                          right: 2,
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
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isFav
                                          ? Icons.favorite_rounded
                                          : Icons.favorite_border_rounded,
                                      size: 14,
                                      color: isFav
                                          ? BarakaColors.terracotta
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Bouton Réserver façon Glovo
                    InkWell(
                      onTap: isExpired ? null : widget.onBook,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 95,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isExpired
                              ? Colors.grey.shade300
                              : BarakaColors.primary,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: isExpired
                              ? null
                              : [
                                  BoxShadow(
                                    color: BarakaColors.primary
                                        .withValues(alpha: 0.25),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          isExpired ? "Expiré" : "Réserver",
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: isExpired ? Colors.grey.shade600 : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
