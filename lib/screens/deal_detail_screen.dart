import 'dart:math';
import 'package:flutter/material.dart';
import '../models/deal.dart';
import '../services/favorites_service.dart';
import '../theme/app_theme.dart';

class DealDetailScreen extends StatefulWidget {
  final Deal deal;
  final Function(String passCode) onBookConfirmed;
  final VoidCallback? onToggleFavorite;

  const DealDetailScreen({
    super.key,
    required this.deal,
    required this.onBookConfirmed,
    this.onToggleFavorite,
  });

  @override
  State<DealDetailScreen> createState() => _DealDetailScreenState();
}

class _DealDetailScreenState extends State<DealDetailScreen> {
  bool _isLoading = false;

  String _generatePassCode() {
    final rnd = Random();
    return (100000 + rnd.nextInt(900000)).toString();
  }

  void _handleBooking() async {
    setState(() => _isLoading = true);
    final code = _generatePassCode();

    await widget.onBookConfirmed(code);

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final deal = widget.deal;

    return Scaffold(
      appBar: AppBar(
        title: Text(deal.businessName),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          ValueListenableBuilder<Set<String>>(
            valueListenable: FavoritesService.instance.favoritesNotifier,
            builder: (context, favs, _) {
              final isFav = favs.contains(deal.id);
              return IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? BarakaColors.terracotta : BarakaColors.textPrimary,
                ),
                tooltip: isFav ? "Retirer des favoris" : "Ajouter aux favoris",
                onPressed: widget.onToggleFavorite,
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
              errorBuilder: (context, error, stackTrace) => Container(
                height: 240,
                color: Colors.grey.shade300,
                child: const Icon(Icons.image_not_supported, size: 60),
              ),
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: BarakaColors.sage,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          deal.category,
                          style: const TextStyle(
                            color: BarakaColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        "${deal.remainingCount} restant(s)",
                        style: TextStyle(
                          color: deal.remainingCount <= 2 ? BarakaColors.terracotta : Colors.orange.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    deal.title,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 18, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        deal.location,
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        "${deal.discountedPrice.toStringAsFixed(0)} MAD",
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: BarakaColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "${deal.originalPrice.toStringAsFixed(0)} MAD",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade400,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: BarakaColors.terracotta,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "-${deal.discountPercentage}%",
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text(
                    "Conditions de l'offre",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "• Présentez votre pass numérique directement sur place.\n"
                    "• Offre non cumulable avec d'autres promotions.\n"
                    "• Valable jusqu'à la fin du compte à rebours.",
                    style: TextStyle(color: Colors.grey.shade600, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (widget.onToggleFavorite != null) ...[
                ValueListenableBuilder<Set<String>>(
                  valueListenable: FavoritesService.instance.favoritesNotifier,
                  builder: (context, favs, _) {
                    final isFav = favs.contains(deal.id);
                    return OutlinedButton.icon(
                      onPressed: widget.onToggleFavorite,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isFav ? BarakaColors.terracotta : BarakaColors.textPrimary,
                        side: BorderSide(
                          color: isFav ? BarakaColors.terracotta : BarakaColors.border,
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        size: 20,
                        color: isFav ? BarakaColors.terracotta : null,
                      ),
                      label: Text(
                        isFav ? "Favori" : "Enregistrer",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: ElevatedButton(
                  onPressed: (deal.remainingCount <= 0 || _isLoading) ? null : _handleBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BarakaColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          "Bloquer ce bon plan",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}