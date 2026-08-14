import 'package:equatable/equatable.dart';

import '../../../core/utils/json_codec.dart';
import 'horse_enums.dart';
import 'horse_location.dart';

/// Ajustement individuel issu des feedbacks (pas de ML).
class HorsePersonalAdjustment extends Equatable {
  const HorsePersonalAdjustment({
    this.offsetGrams = 0,
    this.confidence = 0,
    this.feedbackCount = 0,
  });

  final int offsetGrams;
  final double confidence;
  final int feedbackCount;

  HorsePersonalAdjustment copyWith({
    int? offsetGrams,
    double? confidence,
    int? feedbackCount,
  }) {
    return HorsePersonalAdjustment(
      offsetGrams: offsetGrams ?? this.offsetGrams,
      confidence: confidence ?? this.confidence,
      feedbackCount: feedbackCount ?? this.feedbackCount,
    );
  }

  Map<String, dynamic> toJson() => {
    'offsetGrams': offsetGrams,
    'confidence': confidence,
    'feedbackCount': feedbackCount,
  };

  factory HorsePersonalAdjustment.fromJson(Map<String, dynamic> json) {
    return HorsePersonalAdjustment(
      offsetGrams: jsonInt(json['offsetGrams']) ?? 0,
      confidence: jsonDouble(json['confidence']) ?? 0,
      feedbackCount: jsonInt(json['feedbackCount']) ?? 0,
    );
  }

  @override
  List<Object?> get props => [offsetGrams, confidence, feedbackCount];
}

class Horse extends Equatable {
  const Horse({
    required this.id,
    required this.name,
    required this.location,
    required this.clippingLevel,
    required this.coldSensitivity,
    required this.housingType,
    required this.createdAt,
    required this.updatedAt,
    this.coatThickness = CoatThickness.medium,
    this.shelterAvailable = true,
    this.personalAdjustment = const HorsePersonalAdjustment(),
  });

  final String id;
  final String name;
  final ClippingLevel clippingLevel;
  final CoatThickness coatThickness;

  /// 0.0 = très peu frileux, 1.0 = très frileux.
  final double coldSensitivity;
  final HousingType housingType;
  final bool shelterAvailable;
  final HorseLocation location;
  final HorsePersonalAdjustment personalAdjustment;
  final DateTime createdAt;
  final DateTime updatedAt;

  Horse copyWith({
    String? id,
    String? name,
    ClippingLevel? clippingLevel,
    CoatThickness? coatThickness,
    double? coldSensitivity,
    HousingType? housingType,
    bool? shelterAvailable,
    HorseLocation? location,
    HorsePersonalAdjustment? personalAdjustment,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Horse(
      id: id ?? this.id,
      name: name ?? this.name,
      clippingLevel: clippingLevel ?? this.clippingLevel,
      coatThickness: coatThickness ?? this.coatThickness,
      coldSensitivity: coldSensitivity ?? this.coldSensitivity,
      housingType: housingType ?? this.housingType,
      shelterAvailable: shelterAvailable ?? this.shelterAvailable,
      location: location ?? this.location,
      personalAdjustment: personalAdjustment ?? this.personalAdjustment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'clippingLevel': clippingLevel.name,
    'coatThickness': coatThickness.name,
    'coldSensitivity': coldSensitivity,
    'housingType': housingType.name,
    'shelterAvailable': shelterAvailable,
    'location': location.toJson(),
    'personalAdjustment': personalAdjustment.toJson(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Horse.fromJson(Map<String, dynamic> json) {
    final id = jsonString(json['id']);
    final name = jsonString(json['name']);
    final locationRaw = jsonMap(json['location']);
    if (id == null || name == null || locationRaw == null) {
      throw const FormatException('cheval incomplet');
    }
    return Horse(
      id: id,
      name: name,
      clippingLevel: enumByName(
        ClippingLevel.values,
        json['clippingLevel'],
        ClippingLevel.none,
      ),
      coatThickness: enumByName(
        CoatThickness.values,
        json['coatThickness'],
        CoatThickness.medium,
      ),
      coldSensitivity: jsonDouble(json['coldSensitivity']) ?? 0.5,
      housingType: enumByName(
        HousingType.values,
        json['housingType'],
        HousingType.fieldWithShelter,
      ),
      shelterAvailable: jsonBool(json['shelterAvailable'], fallback: true),
      location: HorseLocation.fromJson(locationRaw),
      personalAdjustment: HorsePersonalAdjustment.fromJson(
        jsonMap(json['personalAdjustment']) ?? const {},
      ),
      createdAt: jsonDate(json['createdAt']),
      updatedAt: jsonDate(json['updatedAt']),
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    clippingLevel,
    coatThickness,
    coldSensitivity,
    housingType,
    shelterAvailable,
    location,
    personalAdjustment,
    createdAt,
    updatedAt,
  ];
}
