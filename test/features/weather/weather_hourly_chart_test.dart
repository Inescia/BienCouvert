import 'package:flutter_test/flutter_test.dart';
import 'package:poney_au_chaud/features/horses/domain/horse_enums.dart';
import 'package:poney_au_chaud/features/weather/domain/hourly_weather.dart';
import 'package:poney_au_chaud/features/weather/presentation/widgets/weather_hourly_chart.dart';

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
    condition: WeatherCondition.clear,
  );
}

void main() {
  test('upcomingWeatherHours part de l’heure courante', () {
    final hours = [
      for (var h = 10; h < 20; h++) _hour(DateTime(2026, 10, 20, h), 10 + h / 10),
    ];
    final current = hours[2]; // 12h

    final slice = upcomingWeatherHours(hours, current, 4);

    expect(slice, hasLength(4));
    expect(slice.first.timestamp.hour, 12);
    expect(slice.last.timestamp.hour, 15);
    expect(nowHourIndex(slice, current), 0);
  });

  test('temperaturePlotY place le chaud en haut', () {
    expect(temperaturePlotY(20, 0, 20, 100), 0);
    expect(temperaturePlotY(0, 0, 20, 100), 100);
    expect(temperaturePlotY(10, 0, 20, 100), 50);
  });

  test('smoothTemperaturePath produit un chemin non vide', () {
    final path = smoothTemperaturePath(const [
      Offset(0, 10),
      Offset(20, 30),
      Offset(40, 15),
    ]);
    expect(path.computeMetrics().isNotEmpty, isTrue);
  });
}
