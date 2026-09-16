import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BarakaLogo extends StatelessWidget {
  final double size;
  final bool showTagline;

  const BarakaLogo({
    super.key,
    this.size = 120,
    this.showTagline = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.22),
            boxShadow: [
              BoxShadow(
                color: BarakaColors.primary.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Container(
              color: BarakaColors.primary,
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
          ),
        ),
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

/// Header de marque élégant pour l'AppBar
class BarakaAppBarTitle extends StatelessWidget {
  const BarakaAppBarTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: BarakaColors.primary.withValues(alpha: 0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: BarakaColors.primary,
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
        ),
        const SizedBox(width: 10),
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
              color: BarakaColors.primary,
            ),
            children: [
              TextSpan(text: "Barak"),
              TextSpan(
                text: "á",
                style: TextStyle(color: BarakaColors.terracotta),
              ),
              TextSpan(
                text: " Marrakech",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: BarakaColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
