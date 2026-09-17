import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class BarakaLogo extends StatelessWidget {
  final double size;
  final bool showTagline;
  final Color? backgroundColor;

  const BarakaLogo({
    super.key,
    this.size = 140,
    this.showTagline = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget logoWidget = Image.asset(
      'assets/images/logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: BarakaColors.primary,
          borderRadius: BorderRadius.circular(size * 0.2),
        ),
        child: Center(
          child: Text(
            "B",
            style: TextStyle(
              fontSize: size * 0.5,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (backgroundColor != null)
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(size * 0.22),
            ),
            child: logoWidget,
          )
        else
          logoWidget,
        if (showTagline) ...[
          const SizedBox(height: 10),
          const Text(
            "Des petits gestes, des grands impacts.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: BarakaColors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ],
    );
  }
}

/// Header de marque moderne pour l'AppBar avec indicateur de localisation
class BarakaAppBarTitle extends StatelessWidget {
  const BarakaAppBarTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/logo.png',
          width: 32,
          height: 32,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: BarakaColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                "B",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
              color: BarakaColors.primary,
            ),
            children: [
              TextSpan(text: "Barak"),
              TextSpan(
                text: "a",
                style: TextStyle(color: BarakaColors.terracotta),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: BarakaColors.sageLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: BarakaColors.primary.withValues(alpha: 0.15),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.place_rounded, size: 11, color: BarakaColors.primary),
              SizedBox(width: 3),
              Text(
                "Marrakech",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: BarakaColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
