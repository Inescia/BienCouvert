import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

/// Icônes de statut noires (heure, batterie) sur fond clair.
const SystemUiOverlayStyle kAppSystemUiOverlay = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.dark,
  statusBarBrightness: Brightness.light,
);

abstract final class AppTypography {
  static const displayFamily = 'Fraunces';
  static const bodyFamily = 'Outfit';

  static TextTheme textTheme = TextTheme(
    displayLarge: const TextStyle(
      fontFamily: displayFamily,
      fontSize: 64,
      fontWeight: FontWeight.w500,
      color: AppColors.chocolate,
      height: 0.95,
      letterSpacing: -1.8,
    ),
    displayMedium: const TextStyle(
      fontFamily: displayFamily,
      fontSize: 42,
      fontWeight: FontWeight.w500,
      color: AppColors.chocolate,
      height: 1.05,
      letterSpacing: -1,
    ),
    headlineLarge: const TextStyle(
      fontFamily: displayFamily,
      fontSize: 30,
      fontWeight: FontWeight.w500,
      color: AppColors.chocolate,
      height: 1.15,
    ),
    headlineMedium: const TextStyle(
      fontFamily: displayFamily,
      fontSize: 22,
      fontWeight: FontWeight.w500,
      color: AppColors.chocolate,
      height: 1.2,
    ),
    titleLarge: const TextStyle(
      fontFamily: bodyFamily,
      fontSize: 19,
      fontWeight: FontWeight.w600,
      color: AppColors.chocolate,
      letterSpacing: -0.2,
    ),
    titleMedium: const TextStyle(
      fontFamily: bodyFamily,
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: AppColors.chocolate,
    ),
    bodyLarge: const TextStyle(
      fontFamily: bodyFamily,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: AppColors.chocolateSoft,
      height: 1.5,
    ),
    bodyMedium: const TextStyle(
      fontFamily: bodyFamily,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.chocolateSoft,
      height: 1.45,
    ),
    bodySmall: const TextStyle(
      fontFamily: bodyFamily,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: AppColors.muted,
      letterSpacing: 0.2,
    ),
    labelLarge: const TextStyle(
      fontFamily: bodyFamily,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.chocolate,
      letterSpacing: 0.3,
    ),
  );
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.cream,
    fontFamily: AppTypography.bodyFamily,
    colorScheme: ColorScheme.light(
      primary: AppColors.copper,
      onPrimary: AppColors.ivory,
      secondary: AppColors.sage,
      onSecondary: AppColors.ivory,
      surface: AppColors.ivory,
      onSurface: AppColors.chocolate,
      error: AppColors.softError,
    ),
  );

  return base.copyWith(
    textTheme: AppTypography.textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      foregroundColor: AppColors.chocolate,
      titleTextStyle: AppTypography.textTheme.titleLarge,
      systemOverlayStyle: kAppSystemUiOverlay,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.ivory.withValues(alpha: 0.95),
      indicatorColor: AppColors.sageSoft,
      elevation: 0,
      height: 66,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return AppTypography.textTheme.bodySmall?.copyWith(
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? AppColors.pine : AppColors.muted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? AppColors.pine : AppColors.muted,
          size: 22,
        );
      }),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
      space: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.chocolate,
      contentTextStyle: AppTypography.textTheme.bodyMedium?.copyWith(
        color: AppColors.ivory,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.ivory,
      selectedColor: AppColors.sageSoft,
      labelStyle: AppTypography.textTheme.bodyMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        side: const BorderSide(color: AppColors.divider),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.ivory.withValues(alpha: 0.92),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: const BorderSide(color: AppColors.pine, width: 1.4),
      ),
    ),
  );
}
