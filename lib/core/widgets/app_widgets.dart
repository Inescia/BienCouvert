import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import 'app_backdrop.dart';

export 'app_backdrop.dart';

/// Marge unique des écrans : 24 px de chaque côté.
/// Avec une AppBar transparente, le haut dégage statut + barre + 20 px.
abstract final class AppPagePadding {
  static const EdgeInsets standard = EdgeInsets.all(AppSpacing.lg);
  static const double extraBelowAppBar = 0;

  static EdgeInsets of(BuildContext context, {bool behindAppBar = false}) {
    if (!behindAppBar) return standard;
    return EdgeInsets.fromLTRB(
      AppSpacing.lg,
      MediaQuery.paddingOf(context).top +
          kToolbarHeight +
          extraBelowAppBar +
          AppSpacing.lg,
      AppSpacing.lg,
      AppSpacing.lg,
    );
  }
}

/// AppBar transparente avec 20 px sous le titre et icônes de statut noires.
AppBar appPageBar({Key? key, required Widget title, List<Widget>? actions}) {
  return AppBar(
    key: key,
    title: title,
    actions: actions,
    systemOverlayStyle: kAppSystemUiOverlay,
    bottom: const PreferredSize(
      preferredSize: Size.fromHeight(AppPagePadding.extraBelowAppBar),
      child: SizedBox(height: AppPagePadding.extraBelowAppBar),
    ),
  );
}

/// Contenu qui se compacte et défile quand le clavier s’ouvre.
class AppKeyboardScroll extends StatelessWidget {
  const AppKeyboardScroll({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    Widget scroll = LayoutBuilder(
      builder: (context, constraints) {
        final minHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 0.0;
        return SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: child,
          ),
        );
      },
    );
    if (padding != null) {
      scroll = Padding(padding: padding!, child: scroll);
    }
    return scroll;
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          color: enabled
              ? AppColors.copper
              : AppColors.copper.withValues(alpha: 0.35),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.copper.withValues(alpha: 0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            onTap: isLoading ? null : onPressed,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppColors.ivory,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 18, color: AppColors.ivory),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          label,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: AppColors.ivory, fontSize: 15),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.pine,
          backgroundColor: AppColors.ivory.withValues(alpha: 0.6),
          side: BorderSide(color: AppColors.pine.withValues(alpha: 0.28)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.lg),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        letterSpacing: 1.8,
        fontWeight: FontWeight.w600,
        color: AppColors.muted,
      ),
    );
  }
}

class AppSurface extends StatelessWidget {
  const AppSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.tint,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: (tint ?? AppColors.ivory).withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.95)),
        boxShadow: AppShadows.soft,
      ),
      child: child,
    );
  }
}

class GramBadge extends StatelessWidget {
  const GramBadge({super.key, required this.label, this.large = false});

  final String label;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: TextAlign.center,
      style:
          (large
                  ? Theme.of(context).textTheme.displayLarge
                  : Theme.of(context).textTheme.headlineMedium)
              ?.copyWith(
                color: AppColors.chocolate,
                fontFeatures: const [FontFeature.tabularFigures()],
                fontSize: large && label.length > 4 ? 48 : null,
              ),
    );
  }
}

class WeatherChip extends StatelessWidget {
  const WeatherChip({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: AppColors.weatherBlue),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.chocolateSoft,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class HorseAvatar extends StatelessWidget {
  const HorseAvatar({
    super.key,
    required this.name,
    this.size = 48,
    this.selected = false,
  });

  final String name;
  final double size;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : '?';
    final base = softColorFromName(name);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: base,
        border: Border.all(
          color: selected ? AppColors.pine : AppColors.ivory,
          width: selected ? 2.2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.pine.withValues(alpha: selected ? 0.18 : 0.06),
            blurRadius: selected ? 10 : 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        initial,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppColors.pine,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.36,
        ),
      ),
    );
  }
}
