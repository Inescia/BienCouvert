import '../../horses/domain/horse_enums.dart';
import '../domain/hourly_weather.dart';
import '../domain/wmo_codes.dart';

HourlyForecast parseOpenMeteoForecast(
  Map<String, dynamic> json, {
  DateTime? fetchedAt,
}) {
  final hourly = json['hourly'] as Map<String, dynamic>?;
  if (hourly == null) {
    throw const FormatException('Réponse météo incomplète');
  }

  final times = (hourly['time'] as List<dynamic>? ?? const []).map((e) {
    if (e is num) {
      return DateTime.fromMillisecondsSinceEpoch(
        e.toInt() * 1000,
        isUtc: true,
      ).toLocal();
    }
    return DateTime.parse(e as String);
  }).toList();
  List<double> nums(String key) => (hourly[key] as List<dynamic>? ?? const [])
      .map((e) => (e as num?)?.toDouble() ?? 0)
      .toList();

  final temps = nums('temperature_2m');
  final feels = nums('apparent_temperature');
  final humidity = nums('relative_humidity_2m');
  final precip = nums('precipitation');
  final precipProb = nums('precipitation_probability');
  final wind = nums('wind_speed_10m');
  final gusts = nums('wind_gusts_10m');
  final codes = (hourly['weather_code'] as List<dynamic>? ?? const [])
      .map((e) => (e as num?)?.toInt() ?? 0)
      .toList();

  final hours = <HourlyWeather>[];
  for (var i = 0; i < times.length; i++) {
    final windSpeed = i < wind.length ? wind[i] : 0.0;
    hours.add(
      HourlyWeather(
        timestamp: times[i],
        temperature: i < temps.length ? temps[i] : 0,
        feelsLike: i < feels.length
            ? feels[i]
            : (i < temps.length ? temps[i] : 0),
        humidity: i < humidity.length ? humidity[i] : 0,
        windSpeed: windSpeed,
        windGust: i < gusts.length ? gusts[i] : windSpeed,
        precipitation: i < precip.length ? precip[i] : 0,
        precipitationProbability: i < precipProb.length ? precipProb[i] : 0,
        condition: weatherConditionFromWmo(
          i < codes.length ? codes[i] : 3,
          windSpeedKmh: windSpeed,
        ),
      ),
    );
  }

  return HourlyForecast(
    hours: hours,
    fetchedAt: fetchedAt ?? DateTime.now(),
    freshness: WeatherFreshness.fresh,
  );
}
