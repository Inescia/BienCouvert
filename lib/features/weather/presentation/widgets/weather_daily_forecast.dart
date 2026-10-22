import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../domain/hourly_weather.dart';
import 'weather_now_card.dart';

class WeatherDaySummary {
  const WeatherDaySummary({
    required this.day,
    required this.hours,
    required this.minTemp,
    required this.maxTemp,
    required this.representative,
  });

  final DateTime day;
  final List<HourlyWeather> hours;
  final double minTemp;
  final double maxTemp;
  final HourlyWeather representative;
}

List<WeatherDaySummary> groupWeatherByDay(List<HourlyWeather> hours) {
  final groups = <WeatherDaySummary>[];
  for (final hour in hours) {
    final day = DateTime(
      hour.timestamp.year,
      hour.timestamp.month,
      hour.timestamp.day,
    );
    if (groups.isEmpty || groups.last.day != day) {
      groups.add(
        WeatherDaySummary(
          day: day,
          hours: [hour],
          minTemp: hour.temperature,
          maxTemp: hour.temperature,
          representative: hour,
        ),
      );
    } else {
      final prev = groups.last;
      final nextHours = [...prev.hours, hour];
      final minT = math.min(prev.minTemp, hour.temperature);
      final maxT = math.max(prev.maxTemp, hour.temperature);
      groups[groups.length - 1] = WeatherDaySummary(
        day: day,
        hours: nextHours,
        minTemp: minT,
        maxTemp: maxT,
        representative: _pickRepresentative(nextHours),
      );
    }
  }
  return groups;
}

HourlyWeather _pickRepresentative(List<HourlyWeather> hours) {
  // Priorité à l'après-midi (14h) pour l'icône du jour, sinon le milieu.
  HourlyWeather? best;
  var bestScore = 1 << 30;
  for (final h in hours) {
    final score = (h.timestamp.hour - 14).abs();
    if (score < bestScore) {
      bestScore = score;
      best = h;
    }
  }
  return best ?? hours[hours.length ~/ 2];
}

/// Résumé journalier style iPhone : jour, icône, barre min→max.
class WeatherDailyForecast extends StatelessWidget {
  const WeatherDailyForecast({super.key, required this.days});

  final List<WeatherDaySummary> days;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const SizedBox.shrink();

    final globalMin = days.map((d) => d.minTemp).reduce(math.min);
    final globalMax = days.map((d) => d.maxTemp).reduce(math.max);

    return AppSurface(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PRÉVISIONS SUR ${days.length} JOUR${days.length > 1 ? 'S' : ''}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              letterSpacing: 1.4,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < days.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                color: AppColors.divider.withValues(alpha: 0.55),
              ),
            _DailyRow(
              day: days[i],
              globalMin: globalMin,
              globalMax: globalMax,
            ),
          ],
        ],
      ),
    );
  }
}

class _DailyRow extends StatelessWidget {
  const _DailyRow({
    required this.day,
    required this.globalMin,
    required this.globalMax,
  });

  final WeatherDaySummary day;
  final double globalMin;
  final double globalMax;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final night = isWeatherNight(day.representative.timestamp);
    final rainChance = day.hours
        .map((h) => h.precipitationProbability)
        .fold<double>(0, math.max);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              formatForecastDayLabel(day.day),
              style: textTheme.titleMedium,
            ),
          ),
          Icon(
            weatherConditionIcon(day.representative.condition, night: night),
            size: 22,
            color: AppColors.pine,
          ),
          SizedBox(
            width: 40,
            child: rainChance >= 30
                ? Text(
                    '${rainChance.round()}%',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.weatherBlue,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  )
                : null,
          ),
          SizedBox(
            width: 36,
            child: Text(
              '${day.minTemp.round()}°',
              textAlign: TextAlign.right,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.muted,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _TempRangeBar(
              min: day.minTemp,
              max: day.maxTemp,
              globalMin: globalMin,
              globalMax: globalMax,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            child: Text(
              '${day.maxTemp.round()}°',
              style: textTheme.titleMedium?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TempRangeBar extends StatelessWidget {
  const _TempRangeBar({
    required this.min,
    required this.max,
    required this.globalMin,
    required this.globalMax,
  });

  final double min;
  final double max;
  final double globalMin;
  final double globalMax;

  @override
  Widget build(BuildContext context) {
    final span = math.max(globalMax - globalMin, 1.0);
    final start = ((min - globalMin) / span).clamp(0.0, 1.0);
    final end = ((max - globalMin) / span).clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final left = width * start;
        final barWidth = math.max(width * (end - start), 8.0);

        return SizedBox(
          height: 6,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.mist.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Positioned(
                left: left,
                width: barWidth,
                top: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    gradient: const LinearGradient(
                      colors: [AppColors.weatherBlue, AppColors.copper],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
