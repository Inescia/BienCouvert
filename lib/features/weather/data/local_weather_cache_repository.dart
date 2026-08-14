import '../domain/hourly_weather.dart';
import '../domain/weather_repository.dart';
import '../../../core/utils/local_json_store.dart';
import '../../horses/domain/horse_enums.dart';

class LocalWeatherCacheRepository implements WeatherCacheRepository {
  LocalWeatherCacheRepository(this._store);

  final LocalJsonStore _store;

  String _file(String locationId) => 'weather_$locationId.json';

  @override
  Future<HourlyForecast?> getCached(String locationId) async {
    final raw = await _store.readMap(_file(locationId));
    if (raw == null) return null;
    try {
      final forecast = HourlyForecast.fromJson(raw);
      if (forecast.hours.isEmpty) return null;
      final age = DateTime.now().difference(forecast.fetchedAt);
      final freshness = age.inMinutes < 30
          ? WeatherFreshness.cached
          : WeatherFreshness.stale;
      return HourlyForecast(
        hours: forecast.hours,
        fetchedAt: forecast.fetchedAt,
        freshness: freshness,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(String locationId, HourlyForecast forecast) async {
    await _store.writeMap(_file(locationId), forecast.toJson());
  }

  @override
  Future<void> clear(String locationId) async {
    await _store.delete(_file(locationId));
  }
}
