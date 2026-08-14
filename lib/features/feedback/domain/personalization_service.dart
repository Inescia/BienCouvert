import '../../horses/domain/horse.dart';
import '../../horses/domain/horse_enums.dart';
import 'blanket_feedback.dart';

/// Calcule un offset personnel simple et explicable à partir des feedbacks.
class PersonalizationService {
  const PersonalizationService({
    this.stepGrams = 50,
    this.maxOffsetGrams = 150,
    this.minFeedbacksForAdjust = 2,
  });

  final int stepGrams;
  final int maxOffsetGrams;
  final int minFeedbacksForAdjust;

  HorsePersonalAdjustment compute(List<BlanketFeedback> feedbacks) {
    if (feedbacks.isEmpty) {
      return const HorsePersonalAdjustment();
    }

    final recent = [...feedbacks]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final sample = recent.take(12).toList();

    var coldVotes = 0;
    var warmVotes = 0;
    var perfectVotes = 0;

    for (final f in sample) {
      switch (f.feeling) {
        case FeedbackFeeling.tooCold:
          coldVotes++;
        case FeedbackFeeling.tooWarm:
          warmVotes++;
        case FeedbackFeeling.perfect:
          perfectVotes++;
      }
      if (f.preferredAdjustment == PreferredAdjustment.warmer) coldVotes++;
      if (f.preferredAdjustment == PreferredAdjustment.lighter) warmVotes++;
    }

    final totalSignal = coldVotes + warmVotes;
    if (sample.length < minFeedbacksForAdjust || totalSignal == 0) {
      return HorsePersonalAdjustment(
        offsetGrams: 0,
        confidence: perfectVotes / sample.length,
        feedbackCount: sample.length,
      );
    }

    final net = coldVotes - warmVotes;
    final steps = (net / 2).round().clamp(-3, 3);
    final offset = (steps * stepGrams).clamp(-maxOffsetGrams, maxOffsetGrams);
    final confidence = (totalSignal / sample.length).clamp(0.0, 1.0).toDouble();

    return HorsePersonalAdjustment(
      offsetGrams: offset,
      confidence: confidence,
      feedbackCount: sample.length,
    );
  }
}
