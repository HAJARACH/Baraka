import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Fond d'écran aux couleurs Baraka (Beige #FAF7F2) avec motif Zellige marocain discret
class ZelligeBackground extends StatelessWidget {
  final Widget child;
  final double patternOpacity;
  final Color backgroundColor;

  const ZelligeBackground({
    super.key,
    required this.child,
    this.patternOpacity = 1.0,
    this.backgroundColor = BarakaColors.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Motif Zellige marocain géométrique discret
          Opacity(
            opacity: patternOpacity,
            child: Image.asset(
              'assets/images/zellige_bg.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          ),
          // Contenu au premier plan
          child,
        ],
      ),
    );
  }
}
