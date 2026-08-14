import '../../horses/domain/horse_enums.dart';
import '../../horses/domain/horse_location.dart';
import '../domain/hourly_weather.dart';
import '../domain/weather_repository.dart';

/// Scénario météo réaliste type soirée pluvieuse → nuit froide (Bordeaux).
class MockWeatherRepository implements WeatherRepository {
  MockWeatherRepository({this._anchor});

  final DateTime? _anchor;

  @override
  Future<HourlyForecast> getHourlyForecast(
    HorseLocation location, {
    DateTime? from,
    int hours = 24,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));

    final start = _alignedHour(from ?? _anchor ?? DateTime.now());
    final scenario = _buildScenario(start, hours);

    return HourlyForecast(
      hours: scenario,
      fetchedAt: DateTime.now(),
      freshness: WeatherFreshness.fresh,
    );
  }

  DateTime _alignedHour(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day, dt.hour);

  List<HourlyWeather> _buildScenario(DateTime start, int hours) {
    const temps = [
      9.0,
      8.0,
      8.0,
      7.0,
      6.0,
      5.0,
      4.0,
      4.0,
      3.0,
      3.0,
      2.5,
      2.0,
      2.0,
      3.0,
      4.0,
      5.0,
      7.0,
      9.0,
      11.0,
      12.0,
      13.0,
      12.0,
      10.0,
      9.0,
    ];
    const winds = [
      18.0,
      20.0,
      22.0,
      24.0,
      25.0,
      27.0,
      24.0,
      20.0,
      18.0,
      16.0,
      14.0,
      12.0,
      10.0,
      10.0,
      12.0,
      14.0,
      15.0,
      16.0,
      14.0,
      12.0,
      10.0,
      12.0,
      14.0,
      16.0,
    ];
    const humidity = [
      88.0,
      90.0,
      91.0,
      92.0,
      93.0,
      94.0,
      92.0,
      90.0,
      88.0,
      86.0,
      85.0,
      84.0,
      82.0,
      80.0,
      78.0,
      75.0,
      72.0,
      70.0,
      68.0,
      70.0,
      74.0,
      78.0,
      82.0,
      85.0,
    ];
    const precip = [
      1.2,
      1.5,
      1.8,
      2.0,
      1.6,
      0.8,
      0.2,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.3,
      0.6,
      0.8,
    ];
    const conditions = [
      WeatherCondition.rain,
      WeatherCondition.rain,
      WeatherCondition.rain,
      WeatherCondition.heavyRain,
      WeatherCondition.rain,
      WeatherCondition.rain,
      WeatherCondition.cloudy,
      WeatherCondition.cloudy,
      WeatherCondition.cloudy,
      WeatherCondition.cloudy,
      WeatherCondition.fog,
      WeatherCondition.fog,
      WeatherCondition.cloudy,
      WeatherCondition.partlyCloudy,
      WeatherCondition.partlyCloudy,
      WeatherCondition.clear,
      WeatherCondition.clear,
      WeatherCondition.clear,
      WeatherCondition.partlyCloudy,
      WeatherCondition.partlyCloudy,
      WeatherCondition.cloudy,
      WeatherCondition.rain,
      WeatherCondition.rain,
      WeatherCondition.rain,
    ];

    return List.generate(hours, (i) {
      final idx = i % 24;
      final ts = start.add(Duration(hours: i));
      final temp = temps[idx];
      final wind = winds[idx];
      final feels = temp - (wind / 20.0) * 1.5;
      return HourlyWeather(
        timestamp: ts,
        temperature: temp,
        feelsLike: feels,
        humidity: humidity[idx],
        windSpeed: wind,
        windGust: wind + 6,
        precipitation: precip[idx],
        precipitationProbability: precip[idx] > 0 ? 80 : 15,
        condition: conditions[idx],
      );
    });
  }
}

/// Service météo avec cache : fresh → cached → stale → unavailable.
class CachedWeatherService {
  CachedWeatherService({
    required this._remote,
    required this._cache,
    this.freshDuration = const Duration(minutes: 30),
    this.staleDuration = const Duration(hours: 6),
  });

  final WeatherRepository _remote;
  final WeatherCacheRepository _cache;
  final Duration freshDuration;
  final Duration staleDuration;

  Future<HourlyForecast> getForecast(
    HorseLocation location, {
    bool forceRefresh = false,
  }) async {
    final cached = await _cache.getCached(location.weatherCacheKey);

    if (!forceRefresh && cached != null) {
      final age = DateTime.now().difference(cached.fetchedAt);
      if (age <= freshDuration) {
        return HourlyForecast(
          hours: cached.hours,
          fetchedAt: cached.fetchedAt,
          freshness: WeatherFreshness.fresh,
        );
      }
    }

    try {
      final fresh = await _remote.getHourlyForecast(location, hours: 72);
      await _cache.save(location.weatherCacheKey, fresh);
      return fresh;
    } catch (_) {
      if (cached != null) {
        final age = DateTime.now().difference(cached.fetchedAt);
        return HourlyForecast(
          hours: cached.hours,
          fetchedAt: cached.fetchedAt,
          freshness: age > staleDuration
              ? WeatherFreshness.stale
              : WeatherFreshness.cached,
        );
      }
      return HourlyForecast(
        hours: const [],
        fetchedAt: DateTime.now(),
        freshness: WeatherFreshness.unavailable,
      );
    }
  }
}
