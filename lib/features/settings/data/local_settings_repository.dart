import 'dart:async';

import '../domain/app_settings.dart';
import '../../../core/utils/local_json_store.dart';

class LocalSettingsRepository implements SettingsRepository {
  LocalSettingsRepository(this._store);

  final LocalJsonStore _store;
  static const _file = 'settings.json';
  final _controller = StreamController<AppSettings>.broadcast();

  @override
  Future<AppSettings> get() async {
    final raw = await _store.readMap(_file);
    if (raw == null) return const AppSettings();
    try {
      return AppSettings.fromJson(raw);
    } catch (_) {
      return const AppSettings();
    }
  }

  @override
  Future<void> save(AppSettings settings) async {
    await _store.writeMap(_file, settings.toJson());
    _controller.add(settings);
  }

  @override
  Stream<AppSettings> watch() async* {
    yield await get();
    yield* _controller.stream;
  }
}
