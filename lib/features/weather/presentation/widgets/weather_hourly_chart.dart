import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../domain/hourly_weather.dart';
import 'weather_now_card.dart';

/// Prévisions horaires style iPhone : défilement horizontal + courbe de température.
class WeatherHourlyChart extends StatelessWidget {
  const WeatherHourlyChart({
    super.key,
    required this.hours,
    this.current,
    this.maxHours = 24,
  });

  final List<HourlyWeather> hours;
  final HourlyWeather? current;
  final int maxHours;

  static const double columnWidth = 58;
  static const double chartHeight = 88;
  static const double headerHeight = 86;

  @override
  Widget build(BuildContext context) {
    final slice = upcomingWeatherHours(hours, current, maxHours);
    if (slice.isEmpty) return const SizedBox.shrink();

    final temps = slice.map((h) => h.temperature).toList();
    final minT = temps.reduce(math.min);
    final maxT = temps.reduce(math.max);
    final span = math.max(maxT - minT, 1.0);
    final paddedMin = minT - span * 0.2;
    final paddedMax = maxT + span * 0.35;
    final nowIndex = nowHourIndex(slice, current);

    return AppSurface(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      tint: AppColors.weatherBlueSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HEURE PAR HEURE',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              letterSpacing: 1.4,
              fontWeight: FontWeight.w600,
              color: AppColors.weatherBlue,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              width: columnWidth * slice.length,
              height: headerHeight + chartHeight,
              child: Stack(
                children: [
                  Positioned(
                    top: headerHeight,
                    left: 0,
                    right: 0,
                    height: chartHeight,
                    child: CustomPaint(
                      painter: TemperatureCurvePainter(
                        temperatures: temps,
                        minTemp: paddedMin,
                        maxTemp: paddedMax,
                        columnWidth: columnWidth,
                        lineColor: AppColors.pine,
                        fillColor: AppColors.pine.withValues(alpha: 0.14),
                        highlightIndex: nowIndex,
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < slice.length; i++)
                        _HourColumn(
                          hour: slice[i],
                          isNow: i == nowIndex,
                          tempY: temperaturePlotY(
                            slice[i].temperature,
                            paddedMin,
                            paddedMax,
                            chartHeight,
                          ),
                          width: columnWidth,
                          headerHeight: headerHeight,
                          chartHeight: chartHeight,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HourColumn extends StatelessWidget {
  const _HourColumn({
    required this.hour,
    required this.isNow,
    required this.tempY,
    required this.width,
    required this.headerHeight,
    required this.chartHeight,
  });

  final HourlyWeather hour;
  final bool isNow;
  final double tempY;
  final double width;
  final double headerHeight;
  final double chartHeight;

  @override
  Widget build(BuildContext context) {
    final night = isWeatherNight(hour.timestamp);
    final textTheme = Theme.of(context).textTheme;
    final labelColor = isNow ? AppColors.pine : AppColors.chocolateSoft;
    final showRainChance = hour.precipitationProbability >= 30;

    return SizedBox(
      width: width,
      child: Column(
        children: [
          SizedBox(
            height: headerHeight,
            child: Column(
              children: [
                Text(
                  isNow ? 'Maintenant' : formatHour(hour.timestamp),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: labelColor,
                    fontWeight: isNow ? FontWeight.w700 : FontWeight.w500,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 10),
                Icon(
                  weatherConditionIcon(hour.condition, night: night),
                  size: 24,
                  color: AppColors.pine,
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 14,
                  child: showRainChance
                      ? Text(
                          '${hour.precipitationProbability.round()} %',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.weatherBlue,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
          SizedBox(
            height: chartHeight,
            width: width,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  // Légèrement au-dessus du point de la courbe.
                  top: (tempY - 26).clamp(0.0, chartHeight - 22),
                  left: 0,
                  right: 0,
                  child: Text(
                    '${hour.temperature.round()}°',
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium?.copyWith(
                      color: isNow ? AppColors.pine : AppColors.chocolate,
                      fontWeight: isNow ? FontWeight.w700 : FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

@visibleForTesting
class TemperatureCurvePainter extends CustomPainter {
  TemperatureCurvePainter({
    required this.temperatures,
    required this.minTemp,
    required this.maxTemp,
    required this.columnWidth,
    required this.lineColor,
    required this.fillColor,
    required this.highlightIndex,
  });

  final List<double> temperatures;
  final double minTemp;
  final double maxTemp;
  final double columnWidth;
  final Color lineColor;
  final Color fillColor;
  final int highlightIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (temperatures.length < 2) return;

    final points = <Offset>[];
    for (var i = 0; i < temperatures.length; i++) {
      final x = columnWidth * (i + 0.5);
      final y = temperaturePlotY(
        temperatures[i],
        minTemp,
        maxTemp,
        size.height,
      );
      points.add(Offset(x, y));
    }

    final path = smoothTemperaturePath(points);
    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(0, size.height),
          [fillColor, fillColor.withValues(alpha: 0.02)],
        ),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
    );

    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final isHighlight = i == highlightIndex;
      canvas.drawCircle(
        p,
        isHighlight ? 4.5 : 3,
        Paint()..color = isHighlight ? AppColors.copper : lineColor,
      );
      canvas.drawCircle(
        p,
        isHighlight ? 2.2 : 1.4,
        Paint()..color = AppColors.ivory,
      );
    }
  }

  @override
  bool shouldRepaint(covariant TemperatureCurvePainter oldDelegate) {
    return oldDelegate.temperatures != temperatures ||
        oldDelegate.minTemp != minTemp ||
        oldDelegate.maxTemp != maxTemp ||
        oldDelegate.highlightIndex != highlightIndex ||
        oldDelegate.columnWidth != columnWidth;
  }
}

@visibleForTesting
double temperaturePlotY(
  double temp,
  double minTemp,
  double maxTemp,
  double height,
) {
  final span = math.max(maxTemp - minTemp, 1.0);
  final t = ((temp - minTemp) / span).clamp(0.0, 1.0);
  // Haut = chaud, bas = froid (comme iPhone).
  return height * (1 - t);
}

@visibleForTesting
Path smoothTemperaturePath(List<Offset> points) {
  final path = Path()..moveTo(points.first.dx, points.first.dy);
  if (points.length == 2) {
    path.lineTo(points[1].dx, points[1].dy);
    return path;
  }
  for (var i = 0; i < points.length - 1; i++) {
    final p0 = points[i];
    final p1 = points[i + 1];
    final controlX = (p0.dx + p1.dx) / 2;
    path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
  }
  return path;
}

@visibleForTesting
List<HourlyWeather> upcomingWeatherHours(
  List<HourlyWeather> hours,
  HourlyWeather? current,
  int maxHours,
) {
  if (hours.isEmpty) return const [];
  var start = 0;
  if (current != null) {
    final idx = hours.indexWhere((h) => h.timestamp == current.timestamp);
    if (idx >= 0) {
      start = idx;
    } else {
      final now = current.timestamp;
      start = hours.indexWhere((h) => !h.timestamp.isBefore(now));
      if (start < 0) start = 0;
    }
  }
  final end = math.min(start + maxHours, hours.length);
  return hours.sublist(start, end);
}

@visibleForTesting
int nowHourIndex(List<HourlyWeather> hours, HourlyWeather? current) {
  if (current == null || hours.isEmpty) return 0;
  final idx = hours.indexWhere((h) => h.timestamp == current.timestamp);
  return idx >= 0 ? idx : 0;
}
