import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../home/presentation/providers.dart';
import '../../domain/recommendation.dart';

class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(homeRecommendationProvider);
    final horse = ref.watch(selectedHorseProvider);

    return Scaffold(
      appBar: appPageBar(
        title: Text(
          horse == null ? 'Prévisions' : 'Prévisions · ${horse.name}',
        ),
      ),
      extendBodyBehindAppBar: true,
      body: AppBackdrop(
        child: async.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.pine),
          ),
          error: (e, _) => Padding(
            padding: AppPagePadding.of(context, behindAppBar: true),
            child: AppSurface(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Impossible de charger les prévisions.'),
                  const SizedBox(height: AppSpacing.md),
                  SecondaryButton(
                    label: 'Réessayer',
                    onPressed: () =>
                        ref.read(homeRecommendationProvider.notifier).refresh(),
                  ),
                ],
              ),
            ),
          ),
          data: (state) {
            final periods = state.timeline?.periods ?? const [];
            if (periods.isEmpty) {
              return const Center(
                child: Text(
                  'Pas encore de prévisions pour ces prochains jours.',
                ),
              );
            }
            final groups = _groupByDay(periods);
            return ListView.builder(
              padding: AppPagePadding.of(context, behindAppBar: true),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return _DaySection(
                  label: formatForecastDayLabel(group.day),
                  periods: group.periods,
                  current: state.current,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _DayGroup {
  const _DayGroup({required this.day, required this.periods});

  final DateTime day;
  final List<RecommendationPeriod> periods;
}

List<_DayGroup> _groupByDay(List<RecommendationPeriod> periods) {
  final groups = <_DayGroup>[];
  for (final period in periods) {
    final day = DateTime(
      period.start.year,
      period.start.month,
      period.start.day,
    );
    if (groups.isEmpty || groups.last.day != day) {
      groups.add(_DayGroup(day: day, periods: [period]));
    } else {
      groups.last.periods.add(period);
    }
  }
  return groups;
}

class _DaySection extends StatelessWidget {
  const _DaySection({
    required this.label,
    required this.periods,
    required this.current,
  });

  final String label;
  final List<RecommendationPeriod> periods;
  final RecommendationPeriod? current;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md, left: 2),
            child: Text(
              label,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          ...List.generate(periods.length, (index) {
            final period = periods[index];
            return _PeriodTile(
              period: period,
              isCurrent: current == period,
              isLast: index == periods.length - 1,
            );
          }),
        ],
      ),
    );
  }
}

class _PeriodTile extends StatelessWidget {
  const _PeriodTile({
    required this.period,
    required this.isCurrent,
    required this.isLast,
  });

  final RecommendationPeriod period;
  final bool isCurrent;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: isCurrent ? AppColors.copper : AppColors.sage,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: AppColors.divider),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.lg),
              child: AppSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${formatHour(period.start)} → ${formatHour(period.end)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      period.grams.label,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      period.reason.summary,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (isCurrent) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Maintenant',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.copper,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
