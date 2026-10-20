import 'package:equatable/equatable.dart';

import '../../horses/domain/horse_enums.dart';
import '../../horses/domain/horse_time_window.dart';
import '../../weather/domain/hourly_weather.dart';
import 'blanket_grams.dart';
import 'recommendation.dart';

/// Recommandation agrégée sur une plage horaire utilisateur.
class WindowRecommendation extends Equatable {
  const WindowRecommendation({
    required this.window,
    required this.start,
    required this.end,
    required this.grams,
    required this.gramsMin,
    required this.gramsMax,
    required this.confidence,
    required this.summary,
    required this.temperatureMinC,
    required this.temperatureMaxC,
    required this.isCurrent,
  });

  final HorseTimeWindow window;
  final DateTime start;
  final DateTime end;
  final BlanketGrams grams;
  final BlanketGrams gramsMin;
  final BlanketGrams gramsMax;
  final ConfidenceLevel confidence;
  final String summary;
  final double temperatureMinC;
  final double temperatureMaxC;
  final bool isCurrent;

  bool get hasVariation => gramsMin != gramsMax;

  String get variationLabel {
    if (!hasVariation) return 'Stable sur la plage';
    return 'Variation ${gramsMin.heroLabel} → ${gramsMax.heroLabel}';
  }

  @override
  List<Object?> get props => [
    window,
    start,
    end,
    grams,
    gramsMin,
    gramsMax,
    confidence,
    summary,
    temperatureMinC,
    temperatureMaxC,
    isCurrent,
  ];
}

/// Agrège les recommandations horaires sur une fenêtre [start, end).
class WindowRecommendationAggregator {
  const WindowRecommendationAggregator();

  WindowRecommendation? forWindow({
    required HorseTimeWindow window,
    required List<HourlyRecommendation> hourly,
    required List<HourlyWeather> weather,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final occ = window.nextOccurrence(clock);
    return aggregate(
      window: window,
      start: occ.start,
      end: occ.end,
      hourly: hourly,
      weather: weather,
      now: clock,
    );
  }

  WindowRecommendation? aggregate({
    required HorseTimeWindow window,
    required DateTime start,
    required DateTime end,
    required List<HourlyRecommendation> hourly,
    required List<HourlyWeather> weather,
    DateTime? now,
  }) {
    if (!end.isAfter(start)) return null;

    final hours = hourly
        .where((h) => !h.start.isBefore(start) && h.start.isBefore(end))
        .toList();
    if (hours.isEmpty) return null;

    final temps = weather
        .where((w) => !w.timestamp.isBefore(start) && w.timestamp.isBefore(end))
        .map((w) => w.temperature)
        .toList();

    HourlyRecommendation pick = hours.first;
    for (final h in hours.skip(1)) {
      if (_coversMore(h.grams, pick.grams) ||
          (h.grams == pick.grams && h.score > pick.score)) {
        pick = h;
      }
    }

    var gramsMin = hours.first.grams;
    var gramsMax = hours.first.grams;
    for (final h in hours) {
      if (_rank(h.grams) < _rank(gramsMin)) gramsMin = h.grams;
      if (_rank(h.grams) > _rank(gramsMax)) gramsMax = h.grams;
    }

    final tempMin = temps.isEmpty
        ? 0.0
        : temps.reduce((a, b) => a < b ? a : b);
    final tempMax = temps.isEmpty
        ? 0.0
        : temps.reduce((a, b) => a > b ? a : b);
    final tempSpan = tempMax - tempMin;
    final gramSpan = _rank(gramsMax) - _rank(gramsMin);

    final confidence = _confidence(
      hourConfidences: hours.map((h) => h.reason.confidence),
      tempSpanC: tempSpan,
      gramSpan: gramSpan,
    );

    final clock = now ?? DateTime.now();
    final isCurrent = !clock.isBefore(start) && clock.isBefore(end);

    final summary = _summary(
      grams: pick.grams,
      gramsMin: gramsMin,
      gramsMax: gramsMax,
      tempMin: tempMin,
      tempMax: tempMax,
      tempsAvailable: temps.isNotEmpty,
    );

    return WindowRecommendation(
      window: window,
      start: start,
      end: end,
      grams: pick.grams,
      gramsMin: gramsMin,
      gramsMax: gramsMax,
      confidence: confidence,
      summary: summary,
      temperatureMinC: tempMin,
      temperatureMaxC: tempMax,
      isCurrent: isCurrent,
    );
  }

  List<WindowRecommendation> forHorseWindows({
    required List<HorseTimeWindow> windows,
    required List<HourlyRecommendation> hourly,
    required List<HourlyWeather> weather,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final results = <WindowRecommendation>[];
    for (final window in windows) {
      final reco = forWindow(
        window: window,
        hourly: hourly,
        weather: weather,
        now: clock,
      );
      if (reco != null) results.add(reco);
    }
    results.sort((a, b) {
      if (a.isCurrent && !b.isCurrent) return -1;
      if (!a.isCurrent && b.isCurrent) return 1;
      return a.start.compareTo(b.start);
    });
    return results;
  }

  bool _coversMore(BlanketGrams a, BlanketGrams b) => _rank(a) > _rank(b);

  /// Ordre de « couverture » : none < sheet < fills croissants.
  int _rank(BlanketGrams g) {
    if (g.isNone) return 0;
    if (g.isSheet) return 1;
    return 2 + g.value;
  }

  ConfidenceLevel _confidence({
    required Iterable<ConfidenceLevel> hourConfidences,
    required double tempSpanC,
    required int gramSpan,
  }) {
    var level = ConfidenceLevel.reliable;
    for (final c in hourConfidences) {
      if (c == ConfidenceLevel.unusual) {
        level = ConfidenceLevel.unusual;
        break;
      }
      if (c == ConfidenceLevel.watch && level == ConfidenceLevel.reliable) {
        level = ConfidenceLevel.watch;
      }
    }
    if (tempSpanC >= 12 || gramSpan >= 200) {
      return ConfidenceLevel.unusual;
    }
    if (tempSpanC >= 6 || gramSpan >= 100) {
      if (level == ConfidenceLevel.reliable) return ConfidenceLevel.watch;
    }
    return level;
  }

  String _summary({
    required BlanketGrams grams,
    required BlanketGrams gramsMin,
    required BlanketGrams gramsMax,
    required double tempMin,
    required double tempMax,
    required bool tempsAvailable,
  }) {
    if (!tempsAvailable) return grams.label;
    final tempBit = tempMin.round() == tempMax.round()
        ? '${tempMin.round()}°C'
        : '${tempMin.round()}→${tempMax.round()}°C';
    if (gramsMin == gramsMax) {
      return '${grams.label} · $tempBit';
    }
    return '${grams.label} · $tempBit · var. ${gramsMin.heroLabel}–${gramsMax.heroLabel}';
  }
}
