import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';

/// Logo Bien Couvert (tête de cheval + sapin).
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 88, this.showRing = true});

  static const assetPath = 'assets/branding/logo.png';

  final double size;
  final bool showRing;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Bien Couvert',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          showRing ? size * 0.22 : size * 0.18,
        ),
        child: Image.asset(
          assetPath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

/// Petite marque pour avatars / hero.
class BrandGlyph extends StatelessWidget {
  const BrandGlyph({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) {
    return BrandMark(size: size, showRing: false);
  }
}

/// Fond sapin & neige : dégradé forêt + arbres enneigés très discrets et flous.
class AppBackdrop extends StatelessWidget {
  const AppBackdrop({
    super.key,
    required this.child,
    this.showNappe = true,
    this.intensity = 1,
  });

  final Widget child;
  final bool showNappe;
  final double intensity;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: kAppSystemUiOverlay,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF2F6F3),
                  Color(0xFFE4EDE7),
                  Color(0xFFD5E2D9),
                  Color(0xFFC8D6CE),
                ],
                stops: [0.0, 0.32, 0.68, 1.0],
              ),
            ),
          ),
          // Halo forêt
          Positioned(
            top: -80,
            right: -30,
            child: IgnorePointer(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.sageSoft.withValues(alpha: 0.85 * intensity),
                      AppColors.sageSoft.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (showNappe)
            Positioned.fill(
              child: IgnorePointer(
                child: Image.asset(
                  'assets/bg.png',
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ),

          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

/// Séparateur élégant fin.
class ElegantDivider extends StatelessWidget {
  const ElegantDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: AppColors.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: AppColors.copper,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: AppColors.divider)),
      ],
    );
  }
}

Color softColorFromName(String name) {
  var hash = 0;
  for (final cu in name.codeUnits) {
    hash = (hash * 31 + cu) & 0x7fffffff;
  }
  // Vert sapin → bleu brume
  final hue = 140 + (hash % 50);
  return HSLColor.fromAHSL(1, hue.toDouble(), 0.16, 0.86).toColor();
}
