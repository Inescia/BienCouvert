import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:poney_au_chaud/core/utils/local_json_store.dart';
import 'package:poney_au_chaud/features/horses/data/local_horse_repository.dart';
import 'package:poney_au_chaud/features/horses/domain/horse.dart';
import 'package:poney_au_chaud/features/horses/domain/horse_enums.dart';
import 'package:poney_au_chaud/features/horses/domain/horse_location.dart';
import 'package:poney_au_chaud/features/horses/domain/horse_time_window.dart';

Horse _horse({
  required String id,
  required String name,
  List<HorseTimeWindow> timeWindows = const [],
}) {
  final now = DateTime(2026, 2, 1);
  return Horse(
    id: id,
    name: name,
    clippingLevel: ClippingLevel.none,
    coldSensitivity: 0.5,
    housingType: HousingType.fieldWithShelter,
    location: const HorseLocation(
      id: 'loc',
      label: 'Caen',
      latitude: 49.18,
      longitude: -0.37,
      city: 'Caen',
    ),
    timeWindows: timeWindows,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late Directory dir;
  late LocalHorseRepository repo;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('bien_couvert_horses_');
    repo = LocalHorseRepository(LocalJsonStore(directory: dir));
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  test('save puis getAll / getById / delete', () async {
    final nala = _horse(id: '1', name: 'Nala');
    final tornado = _horse(id: '2', name: 'Tornado');
    await repo.save(nala);
    await repo.save(tornado);

    final all = await repo.getAll();
    expect(all.map((h) => h.name), ['Nala', 'Tornado']);
    expect((await repo.getById('1'))?.name, 'Nala');

    await repo.delete('1');
    expect((await repo.getAll()).map((h) => h.id), ['2']);
    expect(await repo.getById('1'), isNull);
  });

  test('persiste les plages horaires', () async {
    final window = HorseTimeWindow.create(
      startMinutes: 18 * 60,
      endMinutes: 8 * 60,
      notificationsEnabled: true,
    );
    await repo.save(_horse(id: '1', name: 'Nala', timeWindows: [window]));
    final loaded = await repo.getById('1');
    expect(loaded!.timeWindows, hasLength(1));
    expect(loaded.timeWindows.single.startMinutes, 18 * 60);
    expect(loaded.timeWindows.single.endMinutes, 8 * 60);
    expect(loaded.timeWindows.single.notificationsEnabled, isTrue);
  });

  test('cheval sans timeWindows reste valide', () async {
    final store = LocalJsonStore(directory: dir);
    final json = _horse(id: 'legacy', name: 'Pepito').toJson()
      ..remove('timeWindows');
    await store.writeList('horses.json', [json]);
    final all = await repo.getAll();
    expect(all.single.timeWindows, isEmpty);
  });

  test('ignore un JSON cheval invalide', () async {
    final store = LocalJsonStore(directory: dir);
    await store.writeList('horses.json', [
      _horse(id: 'ok', name: 'Pepito').toJson(),
      {'name': 'sans-id'},
      {'not': 'a horse'},
    ]);

    final all = await repo.getAll();
    expect(all, hasLength(1));
    expect(all.single.name, 'Pepito');
  });
}
