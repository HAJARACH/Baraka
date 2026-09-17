import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Fond d'écran avec motif géométrique marocain (Zellige / Arabesques) beige discret
class AppBackground extends StatelessWidget {
  final Widget child;
  final double opacity;
  final Color backgroundColor;
  final ImageRepeat repeat;
  final BoxFit fit;

  const AppBackground({
    super.key,
    required this.child,
    this.opacity = 1.0,
    this.backgroundColor = BarakaColors.background,
    this.repeat = ImageRepeat.repeat,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Motif zellige géométrique marocain discret
          Opacity(
            opacity: opacity,
            child: Image.asset(
              'assets/images/app_background.png',
              fit: fit,
              repeat: repeat,
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
