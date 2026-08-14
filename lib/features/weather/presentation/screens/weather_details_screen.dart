import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../home/presentation/providers.dart';
import '../../domain/hourly_weather.dart';
import '../widgets/weather_now_card.dart';

class WeatherDetailsScreen extends ConsumerWidget {
  const WeatherDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(homeRecommendationProvider);
    final horse = ref.watch(selectedHorseProvider);
    final location = horse?.location.displayName;

    return Scaffold(
      appBar: appPageBar(title: const Text('Météo')),
      extendBodyBehindAppBar: true,
      body: AppBackdrop(
        child: async.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.pine),
          ),
          error: (e, _) => _MessageState(
            icon: Icons.cloud_off_outlined,
            title: 'Impossible de charger la météo',
            subtitle: '$e',
            action: SecondaryButton(
              label: 'Réessayer',
              onPressed: () =>
                  ref.read(homeRecommendationProvider.notifier).refresh(),
            ),
          ),
          data: (state) {
            final hours = state.forecast?.hours ?? const <HourlyWeather>[];
            if (hours.isEmpty) {
              return const _MessageState(
                icon: Icons.cloud_outlined,
                title: 'Pas de données météo',
                subtitle: 'Tire vers le bas pour actualiser.',
              );
            }

            final current = state.currentWeather;
            final groups = _groupHoursByDay(hours);

            return RefreshIndicator(
              color: AppColors.pine,
              onRefresh: () =>
                  ref.read(homeRecommendationProvider.notifier).refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: AppPagePadding.of(context, behindAppBar: true),
                children: [
                  if (current != null) ...[
                    WeatherNowCard(
                      weather: current,
                      location: location,
                      forecast: state.forecast!,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  const SectionTitle('Heure par heure'),
                  const SizedBox(height: AppSpacing.md),
                  for (final group in groups) ...[
                    _DayForecast(group: group, current: current),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DayForecast extends StatelessWidget {
  const _DayForecast({required this.group, this.current});

  final _DayHours group;
  final HourlyWeather? current;

  @override
  Widget build(BuildContext context) {
    final temps = group.hours.map((h) => h.temperature);
    final min = temps.reduce((a, b) => a < b ? a : b).round();
    final max = temps.reduce((a, b) => a > b ? a : b).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm, left: 2),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  formatForecastDayLabel(group.day),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              Text(
                '$min° / $max°',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.muted,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        AppSurface(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.sm,
          ),
          child: Column(
            children: [
              for (var i = 0; i < group.hours.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    color: AppColors.divider.withValues(alpha: 0.55),
                  ),
                _HourRow(
                  hour: group.hours[i],
                  isNow: current?.timestamp == group.hours[i].timestamp,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _HourRow extends StatelessWidget {
  const _HourRow({required this.hour, required this.isNow});

  final HourlyWeather hour;
  final bool isNow;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final night = isWeatherNight(hour.timestamp);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: isNow ? AppColors.sageSoft.withValues(alpha: 0.55) : null,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              formatHour(hour.timestamp),
              style: textTheme.titleMedium?.copyWith(
                color: isNow ? AppColors.pine : AppColors.chocolate,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Icon(
            weatherConditionIcon(hour.condition, night: night),
            size: 22,
            color: AppColors.pine,
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 44,
            child: Text(
              '${hour.temperature.round()}°',
              style: textTheme.titleLarge?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isNow
                      ? 'Maintenant · ${hour.condition.labelFr}'
                      : hour.condition.labelFr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: isNow ? FontWeight.w600 : FontWeight.w400,
                    color: isNow ? AppColors.pine : AppColors.chocolateSoft,
                  ),
                ),
                Text(
                  _hourMeta(hour),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _hourMeta(HourlyWeather hour) {
    final parts = <String>[
      '${hour.windSpeed.round()} km/h',
      '${hour.humidity.round()} % humidité',
    ];
    if (hour.precipitation > 0) {
      parts.add('${hour.precipitation.toStringAsFixed(1)} mm');
    } else if (hour.precipitationProbability >= 40) {
      parts.add('${hour.precipitationProbability.round()} % pluie');
    }
    return parts.join(' · ');
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppPagePadding.of(context, behindAppBar: true),
        child: AppSurface(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: AppColors.pine),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (action != null) ...[
                const SizedBox(height: AppSpacing.lg),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DayHours {
  const _DayHours({required this.day, required this.hours});

  final DateTime day;
  final List<HourlyWeather> hours;
}

List<_DayHours> _groupHoursByDay(List<HourlyWeather> hours) {
  final groups = <_DayHours>[];
  for (final hour in hours) {
    final day = DateTime(
      hour.timestamp.year,
      hour.timestamp.month,
      hour.timestamp.day,
    );
    if (groups.isEmpty || groups.last.day != day) {
      groups.add(_DayHours(day: day, hours: [hour]));
    } else {
      groups.last.hours.add(hour);
    }
  }
  return groups;
}
