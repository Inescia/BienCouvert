import 'package:flutter_test/flutter_test.dart';
import 'package:poney_au_chaud/features/feedback/domain/blanket_feedback.dart';
import 'package:poney_au_chaud/features/feedback/domain/personalization_service.dart';
import 'package:poney_au_chaud/features/horses/domain/horse_enums.dart';
import 'package:poney_au_chaud/features/recommendations/domain/blanket_grams.dart';

BlanketFeedback _fb({
  required FeedbackFeeling feeling,
  PreferredAdjustment? preferred,
  DateTime? at,
}) {
  return BlanketFeedback(
    id: 'id-${feeling.name}-${at?.millisecondsSinceEpoch ?? 0}',
    horseId: 'horse',
    createdAt: at ?? DateTime(2026, 1, 1),
    feeling: feeling,
    recommendedGrams: BlanketGrams.g200,
    preferredAdjustment: preferred,
  );
}

void main() {
  const service = PersonalizationService();

  test('sans feedback → offset 0', () {
    final adj = service.compute(const []);
    expect(adj.offsetGrams, 0);
    expect(adj.feedbackCount, 0);
  });

  test('plusieurs trop froid → offset positif', () {
    final feedbacks = List.generate(
      4,
      (i) =>
          _fb(feeling: FeedbackFeeling.tooCold, at: DateTime(2026, 1, i + 1)),
    );
    final adj = service.compute(feedbacks);
    expect(adj.offsetGrams, greaterThan(0));
    expect(adj.feedbackCount, 4);
  });

  test('plusieurs trop chaud → offset négatif', () {
    final feedbacks = List.generate(
      4,
      (i) =>
          _fb(feeling: FeedbackFeeling.tooWarm, at: DateTime(2026, 1, i + 1)),
    );
    final adj = service.compute(feedbacks);
    expect(adj.offsetGrams, lessThan(0));
  });

  test('feedbacks mixtes parfaits → offset proche de 0', () {
    final feedbacks = [
      _fb(feeling: FeedbackFeeling.perfect, at: DateTime(2026, 1, 1)),
      _fb(feeling: FeedbackFeeling.perfect, at: DateTime(2026, 1, 2)),
      _fb(feeling: FeedbackFeeling.perfect, at: DateTime(2026, 1, 3)),
    ];
    final adj = service.compute(feedbacks);
    expect(adj.offsetGrams, 0);
  });
}
