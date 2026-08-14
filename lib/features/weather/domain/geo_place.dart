import 'package:equatable/equatable.dart';

import '../../horses/domain/horse_location.dart';

class GeoPlace extends Equatable {
  const GeoPlace({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.admin1,
    this.admin2,
    this.country,
  });

  final String name;
  final double latitude;
  final double longitude;
  final String? admin1;
  final String? admin2;
  final String? country;

  String get displayLabel {
    final parts = <String>[name];
    final region = admin2 ?? admin1;
    if (region != null && region.isNotEmpty && region != name) {
      parts.add(region);
    }
    if (country != null &&
        country!.isNotEmpty &&
        country != 'France' &&
        country != name) {
      parts.add(country!);
    }
    return parts.join(', ');
  }

  HorseLocation toLocation({String? id}) {
    return HorseLocation(
      id:
          id ??
          '${latitude.toStringAsFixed(4)}_${longitude.toStringAsFixed(4)}',
      label: displayLabel,
      city: name,
      latitude: latitude,
      longitude: longitude,
    );
  }

  @override
  List<Object?> get props => [
    name,
    latitude,
    longitude,
    admin1,
    admin2,
    country,
  ];
}
