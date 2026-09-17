import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Fond d'écran texturé beige avec motifs brodés floraux élégants (aux 4 coins)
class AppBackground extends StatelessWidget {
  final Widget child;
  final double opacity;
  final Color backgroundColor;

  const AppBackground({
    super.key,
    required this.child,
    this.opacity = 1.0,
    this.backgroundColor = BarakaColors.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image de fond texturée beige avec broderies florales
          Opacity(
            opacity: opacity,
            child: Image.asset(
              'assets/images/app_background.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          ),
          // Contenu principal au premier plan
          child,
        ],
      ),
    );
  }
}
