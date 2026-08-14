import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:poney_au_chaud/core/utils/local_json_store.dart';

void main() {
  late Directory dir;
  late LocalJsonStore store;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('bien_couvert_store_');
    store = LocalJsonStore(directory: dir);
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  test('écrit et relit une liste encapsulée v1', () async {
    await store.writeList('items.json', [
      {'id': 'a'},
      {'id': 'b'},
    ]);
    final items = await store.readList('items.json');
    expect(items, [
      {'id': 'a'},
      {'id': 'b'},
    ]);

    final raw = jsonDecode(await File('${dir.path}/items.json').readAsString());
    expect(raw, isA<Map>());
    expect((raw as Map)['schemaVersion'], LocalJsonStore.schemaVersion);
    expect(raw['items'], isA<List>());
    expect(File('${dir.path}/items.json.tmp').existsSync(), isFalse);
  });

  test('accepte une liste legacy sans enveloppe', () async {
    await File('${dir.path}/legacy.json').writeAsString(
      jsonEncode([
        {'id': 'old'},
      ]),
    );
    expect(await store.readList('legacy.json'), [
      {'id': 'old'},
    ]);
  });

  test('JSON corrompu → liste vide', () async {
    await File('${dir.path}/broken.json').writeAsString('{not json');
    expect(await store.readList('broken.json'), isEmpty);
  });

  test('readMap vide ou invalide → null', () async {
    expect(await store.readMap('missing.json'), isNull);
    await File('${dir.path}/empty.json').writeAsString('{}');
    expect(await store.readMap('empty.json'), isNull);
    await File('${dir.path}/bad.json').writeAsString('[]');
    expect(await store.readMap('bad.json'), isNull);
  });

  test('writeMap fusionne schemaVersion et relit les données', () async {
    await store.writeMap('settings.json', {'useMockWeather': false});
    final map = await store.readMap('settings.json');
    expect(map?['useMockWeather'], false);
    expect(map?['schemaVersion'], LocalJsonStore.schemaVersion);
  });

  test('delete retire le fichier', () async {
    await store.writeList('gone.json', [
      {'id': 'x'},
    ]);
    await store.delete('gone.json');
    expect(await store.readList('gone.json'), isEmpty);
    expect(File('${dir.path}/gone.json').existsSync(), isFalse);
  });

  test('deleteAll vide le dossier puis permet de réécrire', () async {
    await store.writeList('horses.json', [
      {'id': 'h1'},
    ]);
    await store.writeMap('settings.json', {'gramStep': 50});
    await store.deleteAll();
    expect(await store.readList('horses.json'), isEmpty);
    expect(await store.readMap('settings.json'), isNull);

    await store.writeList('horses.json', [
      {'id': 'h2'},
    ]);
    expect(await store.readList('horses.json'), [
      {'id': 'h2'},
    ]);
  });
}
