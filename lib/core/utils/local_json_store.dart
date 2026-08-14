import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'json_codec.dart';

/// Stockage JSON local-first, encapsulé pour rester interchangeable.
class LocalJsonStore {
  LocalJsonStore({Directory? directory}) : _overrideDirectory = directory;

  static const schemaVersion = 1;

  final Directory? _overrideDirectory;
  Directory? _directory;
  final _locks = <String, Future<void>>{};

  Future<Directory> _dir() async {
    if (_directory != null) return _directory!;
    if (_overrideDirectory != null) {
      _directory = _overrideDirectory;
      await _directory!.create(recursive: true);
      return _directory!;
    }
    final base = await getApplicationDocumentsDirectory();
    _directory = Directory(p.join(base.path, 'poney_au_chaud'));
    await _directory!.create(recursive: true);
    return _directory!;
  }

  Future<File> _file(String name) async {
    final dir = await _dir();
    return File(p.join(dir.path, name));
  }

  Future<T> _serialized<T>(String name, Future<T> Function() action) {
    final previous = _locks[name] ?? Future<void>.value();
    final run = previous.then((_) => action());
    _locks[name] = run.then((_) {}, onError: (_) {});
    return run;
  }

  Future<Object?> _decodeFile(File file) async {
    if (!await file.exists()) return null;
    final raw = await file.readAsString();
    if (raw.trim().isEmpty) return null;
    try {
      return jsonDecode(raw);
    } on FormatException {
      return null;
    }
  }

  Future<void> _atomicWrite(File file, Object data) async {
    final encoded = jsonEncode(data);
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(encoded, flush: true);
    try {
      await tmp.rename(file.path);
    } on FileSystemException {
      if (await file.exists()) await file.delete();
      await tmp.rename(file.path);
    }
  }

  Future<List<Map<String, dynamic>>> readList(String name) {
    return _serialized(name, () async {
      final decoded = await _decodeFile(await _file(name));
      if (decoded == null) return const [];
      if (decoded is List) return jsonMapList(decoded);
      final map = jsonMap(decoded);
      if (map == null) return const [];
      return jsonMapList(map['items']);
    });
  }

  Future<void> writeList(String name, List<Map<String, dynamic>> items) {
    return _serialized(name, () async {
      await _atomicWrite(await _file(name), {
        'schemaVersion': schemaVersion,
        'items': items,
      });
    });
  }

  Future<Map<String, dynamic>?> readMap(String name) {
    return _serialized(name, () async {
      final decoded = await _decodeFile(await _file(name));
      final map = jsonMap(decoded);
      if (map == null || map.isEmpty) return null;
      return map;
    });
  }

  Future<void> writeMap(String name, Map<String, dynamic> data) {
    return _serialized(name, () async {
      await _atomicWrite(await _file(name), {
        'schemaVersion': schemaVersion,
        ...data,
      });
    });
  }

  Future<void> delete(String name) {
    return _serialized(name, () async {
      final file = await _file(name);
      if (await file.exists()) await file.delete();
    });
  }

  /// Supprime tout le dossier local (chevaux, retours, réglages, cache météo).
  Future<void> deleteAll() async {
    await Future.wait(_locks.values);
    final dir = await _dir();
    if (await dir.exists()) await dir.delete(recursive: true);
    _directory = null;
    _locks.clear();
  }
}
