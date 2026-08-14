import 'package:flutter_test/flutter_test.dart';
import 'package:poney_au_chaud/features/feedback/domain/blanket_feedback.dart';
import 'package:poney_au_chaud/features/feedback/domain/feedback_period.dart';
import 'package:poney_au_chaud/features/horses/domain/horse_enums.dart';
import 'package:poney_au_chaud/features/recommendations/domain/blanket_grams.dart';
import 'package:poney_au_chaud/features/recommendations/domain/recommendation.dart';

void main() {
  test('buildFeedbackPeriodOptions priorise Maintenant', () {
    final now = DateTime.now();
    const reason = RecommendationReason(
      summary: 'test',
      factors: [],
      confidence: ConfidenceLevel.reliable,
    );
    final timeline = RecommendationTimeline(
      generatedAt: now,
      hourly: const [],
      periods: [
        RecommendationPeriod(
          start: now.subtract(const Duration(hours: 6)),
          end: now.subtract(const Duration(hours: 2)),
          grams: BlanketGrams.g150,
          reason: reason,
          representativeScore: 5,
        ),
        RecommendationPeriod(
          start: now.subtract(const Duration(hours: 2)),
          end: now.add(const Duration(hours: 3)),
          grams: BlanketGrams.g200,
          reason: reason,
          representativeScore: 6,
        ),
      ],
    );

    final options = buildFeedbackPeriodOptions(timeline: timeline, now: now);
    expect(options, isNotEmpty);
    expect(options.first.isCurrent, isTrue);
    expect(options.first.title, 'Maintenant');
    expect(options.any((o) => o.title != 'Maintenant'), isTrue);
  });

  test('latestFeedbackForPeriod rattache le dernier retour au créneau', () {
    final start = DateTime(2026, 1, 15, 14);
    final option = FeedbackPeriodOption(
      id: 'now',
      title: 'Maintenant',
      subtitle: '14h → 16h',
      start: start,
      end: start.add(const Duration(hours: 2)),
      recommendedGrams: BlanketGrams.g200,
      isCurrent: true,
    );
    final older = BlanketFeedback(
      id: '1',
      horseId: 'h',
      createdAt: DateTime(2026, 1, 15, 15),
      feeling: FeedbackFeeling.tooCold,
      recommendedGrams: BlanketGrams.g200,
      periodStart: start,
      periodEnd: option.end,
    );
    final newer = BlanketFeedback(
      id: '2',
      horseId: 'h',
      createdAt: DateTime(2026, 1, 15, 16),
      feeling: FeedbackFeeling.perfect,
      recommendedGrams: BlanketGrams.g200,
      usedGrams: BlanketGrams.g250,
      periodStart: start.add(const Duration(minutes: 8)),
      periodEnd: option.end,
    );
    final otherSlot = BlanketFeedback(
      id: '3',
      horseId: 'h',
      createdAt: DateTime(2026, 1, 15, 20),
      feeling: FeedbackFeeling.tooWarm,
      recommendedGrams: BlanketGrams.g150,
      periodStart: start.subtract(const Duration(hours: 6)),
    );

    final found = latestFeedbackForPeriod(
      feedbacks: [older, newer, otherSlot],
      option: option,
    );
    expect(found?.id, '2');
    expect(found?.feeling, FeedbackFeeling.perfect);
    expect(
      latestFeedbackForPeriod(feedbacks: [otherSlot], option: option),
      isNull,
    );
  });
}
