import '../../horses/domain/horse_enums.dart';

/// Codes WMO (Open-Meteo) → conditions internes.
WeatherCondition weatherConditionFromWmo(int code, {double windSpeedKmh = 0}) {
  final mapped = switch (code) {
    0 => WeatherCondition.clear,
    1 || 2 => WeatherCondition.partlyCloudy,
    3 => WeatherCondition.cloudy,
    45 || 48 => WeatherCondition.fog,
    >= 51 && <= 57 => WeatherCondition.rain,
    >= 61 && <= 65 => WeatherCondition.rain,
    66 || 67 => WeatherCondition.heavyRain,
    >= 71 && <= 77 => WeatherCondition.snow,
    80 || 81 => WeatherCondition.rain,
    82 => WeatherCondition.heavyRain,
    85 || 86 => WeatherCondition.snow,
    >= 95 && <= 99 => WeatherCondition.heavyRain,
    _ => WeatherCondition.cloudy,
  };

  if (windSpeedKmh >= 40 &&
      (mapped == WeatherCondition.clear ||
          mapped == WeatherCondition.partlyCloudy ||
          mapped == WeatherCondition.cloudy)) {
    return WeatherCondition.windy;
  }
  return mapped;
}
