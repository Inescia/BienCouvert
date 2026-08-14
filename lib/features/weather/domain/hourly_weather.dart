import 'package:equatable/equatable.dart';

import '../../../core/utils/json_codec.dart';
import '../../horses/domain/horse_enums.dart';

class HourlyWeather extends Equatable {
  const HourlyWeather({
    required this.timestamp,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.windGust,
    required this.precipitation,
    required this.precipitationProbability,
    required this.condition,
  });

  final DateTime timestamp;
  final double temperature;
  final double feelsLike;
  final double humidity;
  final double windSpeed;
  final double windGust;
  final double precipitation;
  final double precipitationProbability;
  final WeatherCondition condition;

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'temperature': temperature,
    'feelsLike': feelsLike,
    'humidity': humidity,
    'windSpeed': windSpeed,
    'windGust': windGust,
    'precipitation': precipitation,
    'precipitationProbability': precipitationProbability,
    'condition': condition.name,
  };

  factory HourlyWeather.fromJson(Map<String, dynamic> json) {
    final timestampRaw = json['timestamp'];
    final timestamp = timestampRaw is String
        ? DateTime.tryParse(timestampRaw)
        : null;
    final temperature = jsonDouble(json['temperature']);
    if (timestamp == null || temperature == null) {
      throw const FormatException('heure météo incomplète');
    }
    return HourlyWeather(
      timestamp: timestamp,
      temperature: temperature,
      feelsLike: jsonDouble(json['feelsLike']) ?? temperature,
      humidity: jsonDouble(json['humidity']) ?? 0,
      windSpeed: jsonDouble(json['windSpeed']) ?? 0,
      windGust: jsonDouble(json['windGust']) ?? 0,
      precipitation: jsonDouble(json['precipitation']) ?? 0,
      precipitationProbability:
          jsonDouble(json['precipitationProbability']) ?? 0,
      condition: enumByName(
        WeatherCondition.values,
        json['condition'],
        WeatherCondition.clear,
      ),
    );
  }

  @override
  List<Object?> get props => [
    timestamp,
    temperature,
    feelsLike,
    humidity,
    windSpeed,
    windGust,
    precipitation,
    precipitationProbability,
    condition,
  ];
}

class HourlyForecast extends Equatable {
  const HourlyForecast({
    required this.hours,
    required this.fetchedAt,
    required this.freshness,
  });

  final List<HourlyWeather> hours;
  final DateTime fetchedAt;
  final WeatherFreshness freshness;

  HourlyWeather? weatherAt(DateTime time) {
    if (hours.isEmpty) return null;
    HourlyWeather? best;
    var bestDiff = const Duration(days: 365);
    for (final h in hours) {
      final diff = (h.timestamp.difference(time)).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        best = h;
      }
    }
    return best;
  }

  Map<String, dynamic> toJson() => {
    'hours': hours.map((h) => h.toJson()).toList(),
    'fetchedAt': fetchedAt.toIso8601String(),
    'freshness': freshness.name,
  };

  factory HourlyForecast.fromJson(Map<String, dynamic> json) {
    final hours = <HourlyWeather>[];
    for (final entry in jsonMapList(json['hours'])) {
      try {
        hours.add(HourlyWeather.fromJson(entry));
      } on FormatException {
        continue;
      }
    }
    return HourlyForecast(
      hours: hours,
      fetchedAt: jsonDate(json['fetchedAt']),
      freshness: enumByName(
        WeatherFreshness.values,
        json['freshness'],
        WeatherFreshness.cached,
      ),
    );
  }

  @override
  List<Object?> get props => [hours, fetchedAt, freshness];
}
