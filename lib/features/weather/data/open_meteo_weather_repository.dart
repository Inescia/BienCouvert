import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/errors/app_failure.dart';
import '../../horses/domain/horse_location.dart';
import '../domain/hourly_weather.dart';
import '../domain/weather_repository.dart';
import 'open_meteo_forecast_parser.dart';
import 'open_meteo_geocoding.dart';

class OpenMeteoWeatherRepository implements WeatherRepository {
  OpenMeteoWeatherRepository({
    http.Client? client,
    OpenMeteoGeocoding? geocoding,
  }) : _client = client ?? http.Client(),
       _geocoding = geocoding ?? OpenMeteoGeocoding(client: client);

  static const _headers = {
    HttpHeaders.acceptHeader: 'application/json',
    HttpHeaders.userAgentHeader: 'BienCouvert/1.0 (Flutter)',
  };

  final http.Client _client;
  final OpenMeteoGeocoding _geocoding;

  @override
  Future<HourlyForecast> getHourlyForecast(
    HorseLocation location, {
    DateTime? from,
    int hours = 72,
  }) async {
    var lat = location.latitude;
    var lon = location.longitude;

    if (lat == null || lon == null) {
      final query = location.city ?? location.label;
      final places = await _geocoding.search(query);
      if (places.isEmpty) {
        throw WeatherUnavailableFailure(
          message: 'Lieu introuvable pour « $query »',
        );
      }
      lat = places.first.latitude;
      lon = places.first.longitude;
    }

    final days = ((hours + 23) ~/ 24).clamp(1, 3);
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': lat.toString(),
      'longitude': lon.toString(),
      'hourly': [
        'temperature_2m',
        'apparent_temperature',
        'relative_humidity_2m',
        'precipitation',
        'precipitation_probability',
        'weather_code',
        'wind_speed_10m',
        'wind_gusts_10m',
      ].join(','),
      'forecast_days': '$days',
      'timezone': 'auto',
      'timeformat': 'unixtime',
      'wind_speed_unit': 'kmh',
    });

    late final http.Response response;
    try {
      response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 12));
    } on Exception catch (e) {
      throw WeatherUnavailableFailure(cause: e);
    }

    if (response.statusCode != 200) {
      throw WeatherUnavailableFailure(
        message: 'Météo indisponible (${response.statusCode})',
      );
    }

    final json = jsonDecode(response.body);
    if (json is! Map<String, dynamic>) {
      throw const WeatherUnavailableFailure(message: 'Réponse météo invalide');
    }

    final forecast = parseOpenMeteoForecast(json);
    final now = from ?? DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 3));
    final filtered = forecast.hours
        .where((h) => !h.timestamp.isBefore(start) && h.timestamp.isBefore(end))
        .toList();
    return HourlyForecast(
      hours: filtered.isEmpty ? forecast.hours : filtered,
      fetchedAt: forecast.fetchedAt,
      freshness: forecast.freshness,
    );
  }
}
