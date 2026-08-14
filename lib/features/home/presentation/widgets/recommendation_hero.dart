import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../recommendations/domain/recommendation.dart';

class RecommendationHero extends StatelessWidget {
  const RecommendationHero({
    super.key,
    required this.horseName,
    required this.period,
    this.onTap,
  });

  final String horseName;
  final RecommendationPeriod period;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.97, end: 1),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        builder: (context, scale, child) {
          return Transform.scale(scale: scale, child: child);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.xl,
            horizontal: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.xl),
            color: AppColors.ivory.withValues(alpha: 0.88),
            border: Border.all(color: AppColors.divider),
            boxShadow: AppShadows.soft,
          ),
          child: Column(
            children: [
              Text(
                horseName.toUpperCase(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  letterSpacing: 2.6,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              GramBadge(label: period.grams.heroLabel, large: true),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'recommandé maintenant',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: AppColors.pine),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'jusqu\'à ${formatHour(period.end)}',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                width: 36,
                height: 2,
                color: AppColors.copper.withValues(alpha: 0.7),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                period.reason.summary,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
