import 'package:flutter_test/flutter_test.dart';
import 'package:poney_au_chaud/features/horses/domain/horse_enums.dart';
import 'package:poney_au_chaud/features/horses/domain/horse_time_window.dart';
import 'package:poney_au_chaud/features/recommendations/domain/blanket_grams.dart';
import 'package:poney_au_chaud/features/recommendations/domain/recommendation.dart';
import 'package:poney_au_chaud/features/recommendations/domain/window_recommendation.dart';
import 'package:poney_au_chaud/features/weather/domain/hourly_weather.dart';

HourlyWeather _weather(DateTime t, double temp) {
  return HourlyWeather(
    timestamp: t,
    temperature: temp,
    feelsLike: temp,
    windSpeed: 10,
    windGust: 12,
    humidity: 70,
    precipitation: 0,
    precipitationProbability: 10,
    condition: WeatherCondition.clear,
  );
}

HourlyRecommendation _hour(
  DateTime t,
  BlanketGrams grams, {
  double score = 1,
  ConfidenceLevel confidence = ConfidenceLevel.reliable,
}) {
  return HourlyRecommendation(
    start: t,
    grams: grams,
    score: score,
    reason: RecommendationReason(
      summary: grams.label,
      factors: const [],
      confidence: confidence,
    ),
    weatherTimestamp: t,
  );
}

void main() {
  const aggregator = WindowRecommendationAggregator();

  test('choisit le grammage le plus couvrant et calcule la variation', () {
    final day = DateTime(2026, 3, 10);
    final window = HorseTimeWindow.create(
      startMinutes: 8 * 60,
      endMinutes: 12 * 60,
    );
    final hourly = [
      _hour(day.add(const Duration(hours: 8)), BlanketGrams.g100, score: 2),
      _hour(day.add(const Duration(hours: 9)), BlanketGrams.g200, score: 4),
      _hour(day.add(const Duration(hours: 10)), BlanketGrams.g150, score: 3),
      _hour(day.add(const Duration(hours: 11)), BlanketGrams.g100, score: 2),
    ];
    final weather = [
      _weather(day.add(const Duration(hours: 8)), 8),
      _weather(day.add(const Duration(hours: 9)), 4),
      _weather(day.add(const Duration(hours: 10)), 6),
      _weather(day.add(const Duration(hours: 11)), 9),
    ];

    final reco = aggregator.aggregate(
      window: window,
      start: day.add(const Duration(hours: 8)),
      end: day.add(const Duration(hours: 12)),
      hourly: hourly,
      weather: weather,
      now: day.add(const Duration(hours: 9)),
    );

    expect(reco, isNotNull);
    expect(reco!.grams, BlanketGrams.g200);
    expect(reco.gramsMin, BlanketGrams.g100);
    expect(reco.gramsMax, BlanketGrams.g200);
    expect(reco.isCurrent, isTrue);
    expect(reco.confidence, ConfidenceLevel.watch); // span temp 5° + grams 100
  });

  test('forte variation de température → unusual', () {
    final day = DateTime(2026, 3, 10);
    final window = HorseTimeWindow.create(
      startMinutes: 0,
      endMinutes: 6 * 60,
    );
    final hourly = [
      for (var h = 0; h < 6; h++)
        _hour(day.add(Duration(hours: h)), BlanketGrams.g200, score: 3),
    ];
    final weather = [
      _weather(day, 12),
      _weather(day.add(const Duration(hours: 1)), 10),
      _weather(day.add(const Duration(hours: 2)), 5),
      _weather(day.add(const Duration(hours: 3)), 0),
      _weather(day.add(const Duration(hours: 4)), -2),
      _weather(day.add(const Duration(hours: 5)), -3),
    ];

    final reco = aggregator.aggregate(
      window: window,
      start: day,
      end: day.add(const Duration(hours: 6)),
      hourly: hourly,
      weather: weather,
    );

    expect(reco!.confidence, ConfidenceLevel.unusual);
    expect(reco.hasVariation, isFalse);
  });
}
