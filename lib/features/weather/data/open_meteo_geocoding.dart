import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/errors/app_failure.dart';
import '../domain/geo_place.dart';

class OpenMeteoGeocoding {
  OpenMeteoGeocoding({http.Client? client}) : _client = client ?? http.Client();

  static const _headers = {
    HttpHeaders.acceptHeader: 'application/json',
    HttpHeaders.userAgentHeader: 'BienCouvert/1.0 (Flutter)',
  };

  final http.Client _client;

  Future<List<GeoPlace>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return const [];

    final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
      'name': trimmed,
      'count': '8',
      'language': 'fr',
      'format': 'json',
    });

    late final http.Response response;
    try {
      response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 8));
    } on Exception catch (e) {
      throw WeatherUnavailableFailure(
        message: 'Recherche de lieu impossible',
        cause: e,
      );
    }

    if (response.statusCode != 200) return const [];

    final json = jsonDecode(response.body);
    if (json is! Map<String, dynamic>) return const [];
    final results = json['results'] as List<dynamic>? ?? const [];
    return results
        .whereType<Map<String, dynamic>>()
        .map(_placeFromJson)
        .toList();
  }

  GeoPlace _placeFromJson(Map<String, dynamic> json) {
    return GeoPlace(
      name: json['name'] as String? ?? 'Lieu',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      admin1: json['admin1'] as String?,
      admin2: json['admin2'] as String?,
      country: json['country'] as String?,
    );
  }
}
