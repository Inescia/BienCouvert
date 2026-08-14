import 'package:flutter/material.dart';

/// Sapin & neige — version marquée : forêt profonde, neige, cuivre discret.
abstract final class AppColors {
  /// Fond neige légèrement teinté sapin.
  static const cream = Color(0xFFE6EDE8);

  /// Surfaces claires.
  static const ivory = Color(0xFFF4F7F5);

  /// Encre très foncée.
  static const chocolate = Color(0xFF121A16);
  static const chocolateSoft = Color(0xFF2A3830);

  /// Vert forêt marqué.
  static const sage = Color(0xFF3D5C4A);
  static const sageDeep = Color(0xFF24382E);
  static const sageSoft = Color(0xFFC5D6CB);

  /// Brume froide.
  static const weatherBlue = Color(0xFF5A6F78);
  static const weatherBlueSoft = Color(0xFFD4DFE4);

  /// Cuivre mat (accent chaud limité).
  static const terracotta = Color(0xFFA86B4C);
  static const caramel = Color(0xFF7D7368);
  static const warmYellow = Color(0xFFDCE6E0);

  static const softError = Color(0xFF9A524C);
  static const softSuccess = Color(0xFF3F6E58);
  static const divider = Color(0xFFC5D0C8);
  static const muted = Color(0xFF6A7870);

  static const frost = Color(0xFFEEF3F0);
  static const mist = Color(0xFFD5E0D9);
  static const nightBlue = Color(0xFF1A2620);
  static const pine = Color(0xFF2F4A3B);
  static const pineDeep = Color(0xFF1C2F26);
  static const forest = Color(0xFF264033);
  static const copper = Color(0xFFB38066);
  static const copperDeep = Color(0xFF865338);
}

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

abstract final class AppRadii {
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 22;
  static const double xl = 28;
}

abstract final class AppShadows {
  static List<BoxShadow> get soft => [
    BoxShadow(
      color: AppColors.pineDeep.withValues(alpha: 0.1),
      blurRadius: 28,
      offset: const Offset(0, 10),
    ),
  ];
}
