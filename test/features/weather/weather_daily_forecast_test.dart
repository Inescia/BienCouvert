import 'package:flutter_test/flutter_test.dart';
import 'package:poney_au_chaud/features/horses/domain/horse_enums.dart';
import 'package:poney_au_chaud/features/weather/domain/hourly_weather.dart';
import 'package:poney_au_chaud/features/weather/presentation/widgets/weather_daily_forecast.dart';

HourlyWeather _hour(DateTime at, double temp) {
  return HourlyWeather(
    timestamp: at,
    temperature: temp,
    feelsLike: temp,
    humidity: 70,
    windSpeed: 10,
    windGust: 15,
    precipitation: 0,
    precipitationProbability: 10,
    condition: WeatherCondition.cloudy,
  );
}

void main() {
  test('groupWeatherByDay agrège min/max et icône représentative', () {
    final hours = [
      _hour(DateTime(2026, 10, 20, 8), 8),
      _hour(DateTime(2026, 10, 20, 14), 14),
      _hour(DateTime(2026, 10, 20, 22), 9),
      _hour(DateTime(2026, 10, 21, 9), 6),
      _hour(DateTime(2026, 10, 21, 15), 11),
    ];

    final days = groupWeatherByDay(hours);

    expect(days, hasLength(2));
    expect(days[0].minTemp, 8);
    expect(days[0].maxTemp, 14);
    expect(days[0].representative.timestamp.hour, 14);
    expect(days[1].minTemp, 6);
    expect(days[1].maxTemp, 11);
  });
}
