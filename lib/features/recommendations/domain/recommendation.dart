import 'package:equatable/equatable.dart';

import '../../horses/domain/horse_enums.dart';
import 'blanket_grams.dart';

enum ReasonFactorKind {
  temperature,
  wind,
  humidity,
  precipitation,
  clipping,
  coat,
  coldSensitivity,
  housing,
  personalAdjustment,
  night,
}

class RecommendationFactor extends Equatable {
  const RecommendationFactor({
    required this.kind,
    required this.label,
    required this.contribution,
  });

  final ReasonFactorKind kind;
  final String label;
  final double contribution;

  @override
  List<Object?> get props => [kind, label, contribution];
}

class RecommendationReason extends Equatable {
  const RecommendationReason({
    required this.summary,
    required this.factors,
    required this.confidence,
  });

  final String summary;
  final List<RecommendationFactor> factors;
  final ConfidenceLevel confidence;

  List<RecommendationFactor> get notableFactors {
    final sorted = [...factors]
      ..sort((a, b) => b.contribution.abs().compareTo(a.contribution.abs()));
    return sorted.take(4).where((f) => f.contribution.abs() >= 0.5).toList();
  }

  @override
  List<Object?> get props => [summary, factors, confidence];
}

class HourlyRecommendation extends Equatable {
  const HourlyRecommendation({
    required this.start,
    required this.grams,
    required this.score,
    required this.reason,
    required this.weatherTimestamp,
  });

  final DateTime start;
  final BlanketGrams grams;
  final double score;
  final RecommendationReason reason;
  final DateTime weatherTimestamp;

  @override
  List<Object?> get props => [start, grams, score, reason, weatherTimestamp];
}

class RecommendationPeriod extends Equatable {
  const RecommendationPeriod({
    required this.start,
    required this.end,
    required this.grams,
    required this.reason,
    required this.representativeScore,
  });

  final DateTime start;
  final DateTime end;
  final BlanketGrams grams;
  final RecommendationReason reason;
  final double representativeScore;

  Duration get duration => end.difference(start);

  @override
  List<Object?> get props => [start, end, grams, reason, representativeScore];
}

class RecommendationTimeline extends Equatable {
  const RecommendationTimeline({
    required this.periods,
    required this.generatedAt,
    required this.hourly,
  });

  final List<RecommendationPeriod> periods;
  final DateTime generatedAt;
  final List<HourlyRecommendation> hourly;

  RecommendationPeriod? get current {
    if (periods.isEmpty) return null;
    final now = DateTime.now();
    for (final p in periods) {
      if (!now.isBefore(p.start) && now.isBefore(p.end)) return p;
    }
    return periods.first;
  }

  RecommendationPeriod? nextAfter(RecommendationPeriod current) {
    final index = periods.indexOf(current);
    if (index < 0) return null;
    for (var i = index + 1; i < periods.length; i++) {
      if (periods[i].grams != current.grams) return periods[i];
    }
    return null;
  }

  @override
  List<Object?> get props => [periods, generatedAt, hourly];
}
