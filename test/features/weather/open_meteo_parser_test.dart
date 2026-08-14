import 'package:flutter_test/flutter_test.dart';
import 'package:poney_au_chaud/features/horses/domain/horse_enums.dart';
import 'package:poney_au_chaud/features/weather/data/open_meteo_forecast_parser.dart';
import 'package:poney_au_chaud/features/weather/domain/wmo_codes.dart';

void main() {
  group('weatherConditionFromWmo', () {
    test('ciel clair / nuageux / brouillard', () {
      expect(weatherConditionFromWmo(0), WeatherCondition.clear);
      expect(weatherConditionFromWmo(2), WeatherCondition.partlyCloudy);
      expect(weatherConditionFromWmo(3), WeatherCondition.cloudy);
      expect(weatherConditionFromWmo(45), WeatherCondition.fog);
    });

    test('pluie et neige', () {
      expect(weatherConditionFromWmo(61), WeatherCondition.rain);
      expect(weatherConditionFromWmo(82), WeatherCondition.heavyRain);
      expect(weatherConditionFromWmo(71), WeatherCondition.snow);
      expect(weatherConditionFromWmo(95), WeatherCondition.heavyRain);
    });

    test('vent fort recouvre un ciel clair', () {
      expect(
        weatherConditionFromWmo(0, windSpeedKmh: 45),
        WeatherCondition.windy,
      );
      expect(
        weatherConditionFromWmo(61, windSpeedKmh: 50),
        WeatherCondition.rain,
      );
    });
  });

  group('parseOpenMeteoForecast', () {
    test('mappe une heure Open-Meteo', () {
      final forecast = parseOpenMeteoForecast({
        'hourly': {
          'time': [1768500000],
          'temperature_2m': [4.2],
          'apparent_temperature': [1.0],
          'relative_humidity_2m': [88],
          'precipitation': [1.4],
          'precipitation_probability': [80],
          'weather_code': [61],
          'wind_speed_10m': [22],
          'wind_gusts_10m': [34],
        },
      }, fetchedAt: DateTime(2026, 1, 15, 18));

      expect(forecast.hours, hasLength(1));
      final hour = forecast.hours.single;
      expect(hour.temperature, 4.2);
      expect(hour.feelsLike, 1.0);
      expect(hour.humidity, 88);
      expect(hour.windSpeed, 22);
      expect(hour.precipitation, 1.4);
      expect(hour.condition, WeatherCondition.rain);
      expect(forecast.freshness, WeatherFreshness.fresh);
    });
  });
}
