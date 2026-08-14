import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../horses/domain/horse_enums.dart';
import '../../domain/hourly_weather.dart';

class WeatherNowCard extends StatelessWidget {
  const WeatherNowCard({
    super.key,
    required this.weather,
    required this.forecast,
    this.location,
    this.onTap,
  });

  final HourlyWeather weather;
  final HourlyForecast forecast;
  final String? location;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final night = isWeatherNight(weather.timestamp);
    final textTheme = Theme.of(context).textTheme;

    final card = AppSurface(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      tint: night ? AppColors.weatherBlueSoft : AppColors.warmYellow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (location != null && location!.isNotEmpty)
            Row(
              children: [
                Icon(
                  Icons.place_rounded,
                  size: 18,
                  color: AppColors.pine.withValues(alpha: 0.85),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    location!,
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.chocolateSoft,
                    ),
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.pine.withValues(alpha: 0.85),
                  ),
              ],
            ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${weather.temperature.round()}°',
                      style: textTheme.displayMedium?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      weather.condition.labelFr,
                      style: textTheme.titleLarge?.copyWith(
                        color: AppColors.pine,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ressenti ${weather.feelsLike.round()}°',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.ivory.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  weatherConditionIcon(weather.condition, night: night),
                  size: 36,
                  color: AppColors.pine,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: 36,
            height: 2,
            color: AppColors.copper.withValues(alpha: 0.7),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              WeatherChip(
                icon: Icons.air,
                label: '${weather.windSpeed.round()} km/h',
              ),
              WeatherChip(
                icon: Icons.water_drop_outlined,
                label: '${weather.humidity.round()} %',
              ),
              if (weather.precipitation > 0)
                WeatherChip(
                  icon: Icons.umbrella_outlined,
                  label: '${weather.precipitation.toStringAsFixed(1)} mm',
                )
              else if (weather.precipitationProbability >= 40)
                WeatherChip(
                  icon: Icons.umbrella_outlined,
                  label: '${weather.precipitationProbability.round()} %',
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _FreshnessBadge(forecast: forecast),
        ],
      ),
    );

    if (onTap == null) return card;

    return GestureDetector(onTap: onTap, child: card);
  }
}

class _FreshnessBadge extends StatelessWidget {
  const _FreshnessBadge({required this.forecast});

  final HourlyForecast forecast;

  @override
  Widget build(BuildContext context) {
    final color = switch (forecast.freshness) {
      WeatherFreshness.fresh => AppColors.softSuccess,
      WeatherFreshness.cached => AppColors.weatherBlue,
      WeatherFreshness.stale => AppColors.terracotta,
      WeatherFreshness.unavailable => AppColors.softError,
    };
    final age = formatRelativeAge(forecast.fetchedAt);
    final label = switch (forecast.freshness) {
      WeatherFreshness.fresh => 'Données à jour · $age',
      WeatherFreshness.cached => 'Depuis le cache · $age',
      WeatherFreshness.stale => 'Données anciennes · $age',
      WeatherFreshness.unavailable => 'Météo indisponible',
    };

    return Row(
      children: [
        Icon(Icons.circle, size: 8, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}

bool isWeatherNight(DateTime time) => time.hour < 7 || time.hour >= 20;

IconData weatherConditionIcon(
  WeatherCondition condition, {
  required bool night,
}) {
  return switch (condition) {
    WeatherCondition.clear =>
      night ? Icons.nights_stay_outlined : Icons.wb_sunny_outlined,
    WeatherCondition.partlyCloudy =>
      night ? Icons.nights_stay_outlined : Icons.wb_cloudy_outlined,
    WeatherCondition.cloudy => Icons.cloud_outlined,
    WeatherCondition.rain => Icons.umbrella_outlined,
    WeatherCondition.heavyRain => Icons.thunderstorm_outlined,
    WeatherCondition.snow => Icons.ac_unit_rounded,
    WeatherCondition.fog => Icons.blur_on_rounded,
    WeatherCondition.windy => Icons.air,
  };
}
