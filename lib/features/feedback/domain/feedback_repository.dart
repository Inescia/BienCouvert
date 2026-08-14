import 'blanket_feedback.dart';

abstract class FeedbackRepository {
  Future<List<BlanketFeedback>> getForHorse(String horseId);
  Future<List<BlanketFeedback>> getAll();
  Future<void> save(BlanketFeedback feedback);
  Future<void> delete(String id);
  Stream<List<BlanketFeedback>> watchForHorse(String horseId);
}
