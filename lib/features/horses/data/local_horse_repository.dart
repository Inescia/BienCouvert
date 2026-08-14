import 'dart:async';

import '../domain/horse.dart';
import '../domain/horse_repository.dart';
import '../../../core/utils/local_json_store.dart';

class LocalHorseRepository implements HorseRepository {
  LocalHorseRepository(this._store);

  final LocalJsonStore _store;
  static const _file = 'horses.json';
  final _controller = StreamController<List<Horse>>.broadcast();

  Future<List<Horse>> _load() async {
    final raw = await _store.readList(_file);
    final horses = <Horse>[];
    for (final map in raw) {
      try {
        horses.add(Horse.fromJson(map));
      } catch (_) {
        continue;
      }
    }
    horses.sort((a, b) => a.name.compareTo(b.name));
    return horses;
  }

  Future<void> _persist(List<Horse> horses) async {
    await _store.writeList(_file, horses.map((h) => h.toJson()).toList());
    _controller.add(horses);
  }

  @override
  Future<List<Horse>> getAll() => _load();

  @override
  Future<Horse?> getById(String id) async {
    final all = await _load();
    try {
      return all.firstWhere((h) => h.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(Horse horse) async {
    final all = await _load();
    final index = all.indexWhere((h) => h.id == horse.id);
    if (index >= 0) {
      all[index] = horse;
    } else {
      all.add(horse);
    }
    await _persist(all);
  }

  @override
  Future<void> delete(String id) async {
    final all = await _load();
    all.removeWhere((h) => h.id == id);
    await _persist(all);
  }

  @override
  Stream<List<Horse>> watchAll() async* {
    yield await _load();
    yield* _controller.stream;
  }
}
