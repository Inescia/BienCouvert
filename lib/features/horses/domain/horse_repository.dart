import 'horse.dart';

abstract class HorseRepository {
  Future<List<Horse>> getAll();
  Future<Horse?> getById(String id);
  Future<void> save(Horse horse);
  Future<void> delete(String id);
  Stream<List<Horse>> watchAll();
}
