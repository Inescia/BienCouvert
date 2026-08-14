import 'package:equatable/equatable.dart';

import '../../../core/utils/json_codec.dart';
import '../../horses/domain/horse_enums.dart';
import '../../recommendations/domain/blanket_grams.dart';
import '../../weather/domain/hourly_weather.dart';

class BlanketFeedback extends Equatable {
  const BlanketFeedback({
    required this.id,
    required this.horseId,
    required this.createdAt,
    required this.feeling,
    required this.recommendedGrams,
    this.usedGrams,
    this.preferredAdjustment,
    this.weatherSnapshot,
    this.note,
    this.periodStart,
    this.periodEnd,
    this.periodLabel,
  });

  final String id;
  final String horseId;
  final DateTime createdAt;
  final FeedbackFeeling feeling;
  final BlanketGrams recommendedGrams;
  final BlanketGrams? usedGrams;
  final PreferredAdjustment? preferredAdjustment;
  final HourlyWeather? weatherSnapshot;
  final String? note;

  /// Période concernée par le retour (ex. nuit dernière, maintenant).
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final String? periodLabel;

  Map<String, dynamic> toJson() => {
    'id': id,
    'horseId': horseId,
    'createdAt': createdAt.toIso8601String(),
    'feeling': feeling.name,
    'recommendedGrams': recommendedGrams.toJson(),
    'usedGrams': usedGrams?.toJson(),
    'preferredAdjustment': preferredAdjustment?.name,
    'weatherSnapshot': weatherSnapshot?.toJson(),
    'note': note,
    'periodStart': periodStart?.toIso8601String(),
    'periodEnd': periodEnd?.toIso8601String(),
    'periodLabel': periodLabel,
  };

  factory BlanketFeedback.fromJson(Map<String, dynamic> json) {
    final id = jsonString(json['id']);
    final horseId = jsonString(json['horseId']);
    if (id == null || horseId == null) {
      throw const FormatException('feedback incomplet');
    }
    HourlyWeather? weatherSnapshot;
    final weatherRaw = jsonMap(json['weatherSnapshot']);
    if (weatherRaw != null) {
      try {
        weatherSnapshot = HourlyWeather.fromJson(weatherRaw);
      } on FormatException {
        weatherSnapshot = null;
      }
    }
    return BlanketFeedback(
      id: id,
      horseId: horseId,
      createdAt: jsonDate(json['createdAt']),
      feeling: enumByName(
        FeedbackFeeling.values,
        json['feeling'],
        FeedbackFeeling.perfect,
      ),
      recommendedGrams: BlanketGrams.fromJson(json['recommendedGrams']),
      usedGrams: json['usedGrams'] != null
          ? BlanketGrams.fromJson(json['usedGrams'])
          : null,
      preferredAdjustment: json['preferredAdjustment'] == null
          ? null
          : enumByName(
              PreferredAdjustment.values,
              json['preferredAdjustment'],
              PreferredAdjustment.warmer,
            ),
      weatherSnapshot: weatherSnapshot,
      note: jsonString(json['note']),
      periodStart: json['periodStart'] == null
          ? null
          : jsonDate(json['periodStart']),
      periodEnd: json['periodEnd'] == null ? null : jsonDate(json['periodEnd']),
      periodLabel: jsonString(json['periodLabel']),
    );
  }

  @override
  List<Object?> get props => [
    id,
    horseId,
    createdAt,
    feeling,
    recommendedGrams,
    usedGrams,
    preferredAdjustment,
    weatherSnapshot,
    note,
    periodStart,
    periodEnd,
    periodLabel,
  ];
}
