import 'dart:async';

import '../domain/blanket_feedback.dart';
import '../domain/feedback_repository.dart';
import '../../../core/utils/local_json_store.dart';

class LocalFeedbackRepository implements FeedbackRepository {
  LocalFeedbackRepository(this._store);

  final LocalJsonStore _store;
  static const _file = 'feedbacks.json';
  final _controller = StreamController<List<BlanketFeedback>>.broadcast();

  Future<List<BlanketFeedback>> _load() async {
    final raw = await _store.readList(_file);
    final items = <BlanketFeedback>[];
    for (final map in raw) {
      try {
        items.add(BlanketFeedback.fromJson(map));
      } catch (_) {
        continue;
      }
    }
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<void> _persist(List<BlanketFeedback> items) async {
    await _store.writeList(_file, items.map((e) => e.toJson()).toList());
    _controller.add(items);
  }

  @override
  Future<List<BlanketFeedback>> getAll() => _load();

  @override
  Future<List<BlanketFeedback>> getForHorse(String horseId) async {
    final all = await _load();
    return all.where((f) => f.horseId == horseId).toList();
  }

  @override
  Future<void> save(BlanketFeedback feedback) async {
    final all = await _load();
    final index = all.indexWhere((f) => f.id == feedback.id);
    if (index >= 0) {
      all[index] = feedback;
    } else {
      all.add(feedback);
    }
    await _persist(all);
  }

  @override
  Future<void> delete(String id) async {
    final all = await _load();
    all.removeWhere((f) => f.id == id);
    await _persist(all);
  }

  @override
  Stream<List<BlanketFeedback>> watchForHorse(String horseId) async* {
    yield await getForHorse(horseId);
    yield* _controller.stream.asyncMap((_) => getForHorse(horseId));
  }
}
