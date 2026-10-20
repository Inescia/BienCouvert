import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../horses/domain/horse_enums.dart';
import '../../../recommendations/domain/window_recommendation.dart';

/// Bloc accueil : recommandations pour les plages saisies sur le profil.
class PassageWindowsCard extends StatelessWidget {
  const PassageWindowsCard({
    super.key,
    required this.recommendations,
    this.horseId,
  });

  final List<WindowRecommendation> recommendations;
  final String? horseId;

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) {
      return AppSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ajoute des plages sur le profil du cheval pour voir '
              'la couverture à préparer à chaque passage.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (horseId != null) ...[
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => context.push('/horses/$horseId'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.pine,
                  padding: EdgeInsets.zero,
                ),
                child: const Text('Configurer les plages'),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < recommendations.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          _PassageTile(recommendation: recommendations[i]),
        ],
      ],
    );
  }
}

class _PassageTile extends StatelessWidget {
  const _PassageTile({required this.recommendation});

  final WindowRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final reco = recommendation;
    final dayLabel = formatForecastDayLabel(reco.start);
    final confidenceColor = switch (reco.confidence) {
      ConfidenceLevel.reliable => AppColors.softSuccess,
      ConfidenceLevel.watch => AppColors.weatherBlue,
      ConfidenceLevel.unusual => AppColors.softError,
    };

    return AppSurface(
      tint: reco.isCurrent
          ? AppColors.sageSoft.withValues(alpha: 0.55)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  reco.window.labelRange,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (reco.isCurrent)
                Text(
                  'En cours',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.pine,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                Text(
                  dayLabel,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                reco.grams.heroLabel,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  reco.variationLabel,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            reco.summary,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: confidenceColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  reco.confidence.labelFr,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              if (reco.window.notificationsEnabled)
                Icon(
                  Icons.notifications_active_outlined,
                  size: 16,
                  color: AppColors.pine.withValues(alpha: 0.8),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
