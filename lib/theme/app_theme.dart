import 'package:flutter/material.dart';

/// Palette de couleurs extraite de la charte graphique et du logo officiel Baraka
class BarakaColors {
  // Vert Émeraude / Forêt Majorelle (Couleur emblématique du B et de "Baraká")
  static const Color primary = Color(0xFF1B4D3E);
  static const Color primaryDark = Color(0xFF10332B);
  static const Color primaryLight = Color(0xFF2E6F5B);

  // Terre Cuite / Terracotta Marrakech (Pétales du zellige central et accent feuille)
  static const Color terracotta = Color(0xFFC25E35);
  static const Color terracottaLight = Color(0xFFFBECE5);
  static const Color terracottaDark = Color(0xFFA64A25);

  // Teintes douces et fonds
  static const Color background = Color(0xFFFAF7F2); // Fond crème naturel du logo
  static const Color surface = Colors.white;
  static const Color sage = Color(0xFFE5EFEA); // Vert sauge doux pour conteneurs & badges
  static const Color sageLight = Color(0xFFF0F6F2);

  // Textes & contrastes
  static const Color textPrimary = Color(0xFF1B2824); // Anthracite végétal
  static const Color textSecondary = Color(0xFF667770);
  static const Color textMuted = Color(0xFF9EABA5);
  static const Color border = Color(0xFFE2DDD5);

  // Accents d'alerte et ocre
  static const Color ochre = Color(0xFFD69E2E); // Ocre marocain
  static const Color discountBadge = Color(0xFFC25E35); // Terracotta pour les remises
}

class BarakaTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: BarakaColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: BarakaColors.primary,
        primary: BarakaColors.primary,
        secondary: BarakaColors.terracotta,
        surface: BarakaColors.surface,
        surfaceTint: Colors.transparent,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: BarakaColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: BarakaColors.textPrimary,
          fontSize: 19,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: BarakaColors.surface,
        elevation: 1.5,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFEFEBE4), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: BarakaColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: BarakaColors.primary,
          side: const BorderSide(color: BarakaColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 4,
        indicatorColor: BarakaColors.sage,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: BarakaColors.primary,
            );
          }
          return const TextStyle(
            fontSize: 12,
            color: BarakaColors.textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: BarakaColors.primary);
          }
          return const IconThemeData(color: BarakaColors.textSecondary);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BarakaColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BarakaColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BarakaColors.primary, width: 2),
        ),
        labelStyle: const TextStyle(color: BarakaColors.textSecondary),
        prefixIconColor: BarakaColors.primary,
      ),
    );
  }
}
