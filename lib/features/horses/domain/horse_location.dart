import 'package:equatable/equatable.dart';

import '../../../core/utils/json_codec.dart';

class HorseLocation extends Equatable {
  const HorseLocation({
    required this.id,
    required this.label,
    this.latitude,
    this.longitude,
    this.city,
  });

  final String id;
  final String label;
  final double? latitude;
  final double? longitude;
  final String? city;

  String get displayName => label.isNotEmpty ? label : (city ?? '');

  HorseLocation copyWith({
    String? id,
    String? label,
    double? latitude,
    double? longitude,
    String? city,
    bool clearCoordinates = false,
  }) {
    return HorseLocation(
      id: id ?? this.id,
      label: label ?? this.label,
      latitude: clearCoordinates ? null : (latitude ?? this.latitude),
      longitude: clearCoordinates ? null : (longitude ?? this.longitude),
      city: city ?? this.city,
    );
  }

  bool get hasCoordinates => latitude != null && longitude != null;

  /// Clé de cache météo : la grille ~100 m, pas l'id du profil.
  String get weatherCacheKey {
    if (!hasCoordinates) return id;
    return '${latitude!.toStringAsFixed(3)}_${longitude!.toStringAsFixed(3)}';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'latitude': latitude,
    'longitude': longitude,
    'city': city,
  };

  factory HorseLocation.fromJson(Map<String, dynamic> json) {
    return HorseLocation(
      id: jsonString(json['id']) ?? '',
      label: jsonString(json['label']) ?? '',
      latitude: jsonDouble(json['latitude']),
      longitude: jsonDouble(json['longitude']),
      city: jsonString(json['city']),
    );
  }

  @override
  List<Object?> get props => [id, label, latitude, longitude, city];
}
