import 'package:flutter_test/flutter_test.dart';
import 'package:poney_au_chaud/features/horses/domain/horse_enums.dart';
import 'package:poney_au_chaud/features/horses/domain/horse_location.dart';
import 'package:poney_au_chaud/features/weather/data/mock_weather_repository.dart';
import 'package:poney_au_chaud/features/weather/domain/hourly_weather.dart';
import 'package:poney_au_chaud/features/weather/domain/weather_repository.dart';

const _location = HorseLocation(
  id: 'loc',
  label: 'Caen',
  latitude: 49.182,
  longitude: -0.371,
  city: 'Caen',
);

HourlyForecast _forecast({
  required DateTime fetchedAt,
  WeatherFreshness freshness = WeatherFreshness.cached,
}) {
  return HourlyForecast(
    hours: [
      HourlyWeather(
        timestamp: fetchedAt,
        temperature: 8,
        feelsLike: 7,
        humidity: 70,
        windSpeed: 10,
        windGust: 14,
        precipitation: 0,
        precipitationProbability: 10,
        condition: WeatherCondition.clear,
      ),
    ],
    fetchedAt: fetchedAt,
    freshness: freshness,
  );
}

class _FakeRemote implements WeatherRepository {
  _FakeRemote({this.error});

  HourlyForecast? forecast;
  Object? error;
  int calls = 0;

  @override
  Future<HourlyForecast> getHourlyForecast(
    HorseLocation location, {
    DateTime? from,
    int hours = 72,
  }) async {
    calls++;
    final err = error;
    if (err != null) throw err;
    return forecast!;
  }
}

class _FakeCache implements WeatherCacheRepository {
  HourlyForecast? stored;

  @override
  Future<HourlyForecast?> getCached(String locationId) async => stored;

  @override
  Future<void> save(String locationId, HourlyForecast forecast) async {
    stored = forecast;
  }

  @override
  Future<void> clear(String locationId) async {
    stored = null;
  }
}

void main() {
  test('cache frais → pas d’appel distant', () async {
    final now = DateTime.now();
    final cache = _FakeCache()..stored = _forecast(fetchedAt: now);
    final remote = _FakeRemote(error: Exception('ne doit pas être appelé'));
    final service = CachedWeatherService(remote: remote, cache: cache);

    final result = await service.getForecast(_location);
    expect(result.freshness, WeatherFreshness.fresh);
    expect(result.hours, isNotEmpty);
    expect(remote.calls, 0);
  });

  test('échec distant + cache récent → cached', () async {
    final fetchedAt = DateTime.now().subtract(const Duration(hours: 2));
    final cache = _FakeCache()..stored = _forecast(fetchedAt: fetchedAt);
    final remote = _FakeRemote(error: Exception('réseau'));
    final service = CachedWeatherService(remote: remote, cache: cache);

    final result = await service.getForecast(_location);
    expect(result.freshness, WeatherFreshness.cached);
    expect(result.hours, isNotEmpty);
    expect(remote.calls, 1);
  });

  test('échec distant + cache trop vieux → stale', () async {
    final fetchedAt = DateTime.now().subtract(const Duration(hours: 8));
    final cache = _FakeCache()..stored = _forecast(fetchedAt: fetchedAt);
    final remote = _FakeRemote(error: Exception('réseau'));
    final service = CachedWeatherService(remote: remote, cache: cache);

    final result = await service.getForecast(_location);
    expect(result.freshness, WeatherFreshness.stale);
    expect(result.hours, isNotEmpty);
  });

  test('aucun cache + échec distant → unavailable', () async {
    final cache = _FakeCache();
    final remote = _FakeRemote(error: Exception('réseau'));
    final service = CachedWeatherService(remote: remote, cache: cache);

    final result = await service.getForecast(_location);
    expect(result.freshness, WeatherFreshness.unavailable);
    expect(result.hours, isEmpty);
  });
}
