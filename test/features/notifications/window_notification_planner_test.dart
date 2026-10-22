import 'package:flutter_test/flutter_test.dart';
import 'package:poney_au_chaud/features/horses/domain/horse.dart';
import 'package:poney_au_chaud/features/horses/domain/horse_enums.dart';
import 'package:poney_au_chaud/features/horses/domain/horse_location.dart';
import 'package:poney_au_chaud/features/horses/domain/horse_time_window.dart';
import 'package:poney_au_chaud/features/notifications/domain/window_notification_planner.dart';
import 'package:poney_au_chaud/features/recommendations/domain/blanket_grams.dart';
import 'package:poney_au_chaud/features/recommendations/domain/window_recommendation.dart';

void main() {
  const planner = WindowNotificationPlanner();
  final now = DateTime(2026, 3, 10, 10);

  Horse horseWith(List<HorseTimeWindow> windows) {
    return Horse(
      id: 'h1',
      name: 'Nala',
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
      timeWindows: windows,
      createdAt: now,
      updatedAt: now,
    );
  }

  WindowRecommendation reco(HorseTimeWindow window) {
    final occ = window.nextOccurrence(now);
    return WindowRecommendation(
      window: window,
      start: occ.start,
      end: occ.end,
      grams: BlanketGrams.g200,
      gramsMin: BlanketGrams.g150,
      gramsMax: BlanketGrams.g200,
      confidence: ConfidenceLevel.watch,
      summary: '200 g',
      temperatureMinC: 2,
      temperatureMaxC: 8,
      isCurrent: false,
    );
  }

  test('ne planifie que les plages avec notif activée', () {
    final on = HorseTimeWindow.create(
      startMinutes: 7 * 60 + 30,
      endMinutes: 9 * 60,
      notificationsEnabled: true,
    );
    final off = HorseTimeWindow.create(
      startMinutes: 18 * 60,
      endMinutes: 8 * 60,
      notificationsEnabled: false,
    );
    final horse = horseWith([on, off]);
    final payloads = planner.plan(
      horse: horse,
      recommendations: [reco(on), reco(off)],
    );
    expect(payloads, hasLength(1));
    expect(payloads.single.windowId, on.id);
    expect(payloads.single.horseName, 'Nala');
    expect(payloads.single.body, contains('200 g'));
    expect(payloads.single.body, contains('À surveiller'));
    expect(payloads.single.startHour, 7);
    expect(payloads.single.startMinute, 30);
  });
}
