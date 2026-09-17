import 'package:flutter/material.dart';
import '../main.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/baraka_logo.dart';

/// Écran intermédiaire après le Splash Screen : permet au client de choisir
/// son grand univers (Alimentaire vs Services) avant d'accéder au feed.
class CategoryHubScreen extends StatelessWidget {
  const CategoryHubScreen({super.key});

  void _navigateToFeed(BuildContext context, String macroCategory) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            MainHomeScreen(initialMacroCategory: macroCategory),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 450),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // En-tête avec logo épuré
                const SizedBox(height: 8),
                const Center(
                  child: BarakaLogo(size: 60, showTagline: false),
                ),
                const SizedBox(height: 12),

                // Titre et sous-titre
                const Text(
                  "Que recherchez-vous ?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: BarakaColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Choisissez votre univers pour découvrir les meilleurs bons plans de Marrakech.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: BarakaColors.textSecondary.withValues(alpha: 0.9),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 24),

                // Les deux grandes cartes de sélection
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // Carte 1 : ALIMENTAIRE
                      _buildMacroCard(
                        context: context,
                        title: "Alimentaire & Gastronomie",
                        subtitle: "Paniers repas, viennoiseries, primeurs...",
                        description:
                            "Sauvez des invendus gourmands de boulangeries, restaurants et épiceries à prix réduits.",
                        chips: ["Boulangerie", "Restaurant", "Épicerie"],
                        icon: Icons.restaurant_rounded,
                        accentColor: BarakaColors.primary,
                        badgeColor: BarakaColors.sage,
                        onTap: () => _navigateToFeed(context, 'Alimentaire'),
                      ),

                      const SizedBox(height: 16),

                      // Carte 2 : SERVICES & COMMERCES
                      _buildMacroCard(
                        context: context,
                        title: "Services & Commerces",
                        subtitle: "Fleuristes, beauté, bien-être, artisanat...",
                        description:
                            "Profitez de bouquets de saison, soins et services de proximité partenaires éco-responsables.",
                        chips: ["Fleuriste", "Soins & Beauté", "Artisanat"],
                        icon: Icons.local_florist_rounded,
                        accentColor: BarakaColors.terracotta,
                        badgeColor: BarakaColors.terracottaLight,
                        onTap: () => _navigateToFeed(context, 'Services'),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),

                // Lien pour tout afficher
                TextButton(
                  onPressed: () => _navigateToFeed(context, 'Tous'),
                  style: TextButton.styleFrom(
                    foregroundColor: BarakaColors.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Explorer tous les bons plans sans filtre",
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMacroCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String description,
    required List<String> chips,
    required IconData icon,
    required Color accentColor,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.22),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ligne du haut : Icône & Titre
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accentColor.withValues(alpha: 0.16),
                          accentColor.withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Icon(icon, color: accentColor, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: BarakaColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: BarakaColors.textSecondary.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: BarakaColors.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),

              // Puces des sous-catégories
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: chips.map((c) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Text(
                      c,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
