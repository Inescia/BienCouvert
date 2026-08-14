import '../../recommendations/domain/blanket_grams.dart';
import '../../recommendations/domain/recommendation.dart';
import '../../../../core/utils/formatters.dart';
import 'blanket_feedback.dart';

/// Option de période pour un feedback clair et contextualisé.
class FeedbackPeriodOption {
  const FeedbackPeriodOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.start,
    required this.end,
    required this.recommendedGrams,
    this.isCurrent = false,
  });

  final String id;
  final String title;
  final String subtitle;
  final DateTime start;
  final DateTime end;
  final BlanketGrams recommendedGrams;
  final bool isCurrent;

  factory FeedbackPeriodOption.fromPeriod(
    RecommendationPeriod period, {
    required DateTime now,
    required bool isCurrent,
  }) {
    return FeedbackPeriodOption(
      id: '${period.start.toIso8601String()}_${period.grams.name}',
      title: _titleFor(period, now: now, isCurrent: isCurrent),
      subtitle:
          '${formatHour(period.start)} → ${formatHour(period.end)} · ${period.grams.label}',
      start: period.start,
      end: period.end,
      recommendedGrams: period.grams,
      isCurrent: isCurrent,
    );
  }
}

String _titleFor(
  RecommendationPeriod period, {
  required DateTime now,
  required bool isCurrent,
}) {
  if (isCurrent) return 'Maintenant';

  final start = period.start;
  final today = DateTime(now.year, now.month, now.day);
  final startDay = DateTime(start.year, start.month, start.day);
  final yesterday = today.subtract(const Duration(days: 1));

  if (startDay == today) {
    if (start.hour < 12) return 'Ce matin';
    if (start.hour < 18) return 'Cet après-midi';
    return 'Ce soir';
  }
  if (startDay == yesterday) {
    if (start.hour >= 18 || period.end.hour <= 8) return 'La nuit dernière';
    return 'Hier';
  }
  return 'Plus tôt';
}

List<FeedbackPeriodOption> buildFeedbackPeriodOptions({
  required RecommendationTimeline? timeline,
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();
  if (timeline == null || timeline.periods.isEmpty) {
    final start = clock.subtract(const Duration(hours: 1));
    return [
      FeedbackPeriodOption(
        id: 'now',
        title: 'Maintenant',
        subtitle: 'Période en cours',
        start: start,
        end: clock.add(const Duration(hours: 2)),
        recommendedGrams: BlanketGrams.g200,
        isCurrent: true,
      ),
    ];
  }

  final current = timeline.current;
  final recent = timeline.periods.where((p) {
    // Périodes dans les ~36 dernières heures jusqu'à maintenant
    return !p.end.isBefore(clock.subtract(const Duration(hours: 36))) &&
        !p.start.isAfter(clock.add(const Duration(hours: 1)));
  }).toList();

  // Priorité : actuelle + périodes passées récentes (max 5)
  final options = <FeedbackPeriodOption>[];
  for (final p in recent.reversed) {
    final isCurrent =
        identical(p, current) ||
        (current != null &&
            p.start == current.start &&
            p.end == current.end &&
            p.grams == current.grams);
    if (!isCurrent && p.start.isAfter(clock)) continue;
    options.add(
      FeedbackPeriodOption.fromPeriod(p, now: clock, isCurrent: isCurrent),
    );
  }

  options.sort((a, b) {
    if (a.isCurrent && !b.isCurrent) return -1;
    if (!a.isCurrent && b.isCurrent) return 1;
    return b.start.compareTo(a.start);
  });

  return options.take(5).toList();
}

const _periodMatchTolerance = Duration(minutes: 30);

/// Dernier retour enregistré pour ce créneau, s’il y en a un.
BlanketFeedback? latestFeedbackForPeriod({
  required Iterable<BlanketFeedback> feedbacks,
  required FeedbackPeriodOption option,
}) {
  BlanketFeedback? latest;
  for (final feedback in feedbacks) {
    final start = feedback.periodStart;
    if (start == null) continue;
    if (start.difference(option.start).abs() > _periodMatchTolerance) {
      continue;
    }
    if (latest == null || feedback.createdAt.isAfter(latest.createdAt)) {
      latest = feedback;
    }
  }
  return latest;
}
