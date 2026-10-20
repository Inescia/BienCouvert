import 'package:flutter_test/flutter_test.dart';
import 'package:poney_au_chaud/features/horses/domain/horse_time_window.dart';

void main() {
  group('HorseTimeWindow', () {
    test('plage journée sans minuit', () {
      final w = HorseTimeWindow.create(
        startMinutes: 7 * 60 + 30,
        endMinutes: 9 * 60,
      );
      expect(w.crossesMidnight, isFalse);
      expect(w.duration, const Duration(hours: 1, minutes: 30));
      expect(w.labelRange, '07h30 → 09h');
    });

    test('plage nuit traverse minuit', () {
      final w = HorseTimeWindow.create(
        startMinutes: 18 * 60,
        endMinutes: 8 * 60,
      );
      expect(w.crossesMidnight, isTrue);
      expect(w.duration, const Duration(hours: 14));
      expect(w.labelRange, '18h → 08h');
    });

    test('nextOccurrence reste sur la plage en cours', () {
      final w = HorseTimeWindow.create(
        startMinutes: 18 * 60,
        endMinutes: 8 * 60,
      );
      final now = DateTime(2026, 3, 10, 22, 0);
      final occ = w.nextOccurrence(now);
      expect(occ.start, DateTime(2026, 3, 10, 18));
      expect(occ.end, DateTime(2026, 3, 11, 8));
      expect(w.contains(now), isTrue);
    });

    test('nextOccurrence passe au lendemain si terminée', () {
      final w = HorseTimeWindow.create(
        startMinutes: 7 * 60,
        endMinutes: 9 * 60,
      );
      final now = DateTime(2026, 3, 10, 12, 0);
      final occ = w.nextOccurrence(now);
      expect(occ.start, DateTime(2026, 3, 11, 7));
      expect(occ.end, DateTime(2026, 3, 11, 9));
    });

    test('JSON round-trip', () {
      final w = HorseTimeWindow.create(
        startMinutes: 12 * 60 + 30,
        endMinutes: 14 * 60,
        notificationsEnabled: true,
      );
      final copy = HorseTimeWindow.fromJson(w.toJson());
      expect(copy.id, w.id);
      expect(copy.startMinutes, w.startMinutes);
      expect(copy.endMinutes, w.endMinutes);
      expect(copy.notificationsEnabled, isTrue);
    });
  });
}
