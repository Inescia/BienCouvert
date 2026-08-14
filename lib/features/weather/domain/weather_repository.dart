import '../../horses/domain/horse_location.dart';
import 'hourly_weather.dart';

abstract class WeatherRepository {
  Future<HourlyForecast> getHourlyForecast(
    HorseLocation location, {
    DateTime? from,
    int hours = 72,
  });
}

abstract class WeatherCacheRepository {
  Future<HourlyForecast?> getCached(String locationId);
  Future<void> save(String locationId, HourlyForecast forecast);
  Future<void> clear(String locationId);
}
