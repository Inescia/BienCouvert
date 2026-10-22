import '../../horses/domain/horse.dart';
import '../../recommendations/domain/window_recommendation.dart';
import 'window_notification_payload.dart';

/// Construit les payloads de notif à partir des plages activées.
class WindowNotificationPlanner {
  const WindowNotificationPlanner();

  List<WindowNotificationPayload> plan({
    required Horse horse,
    required List<WindowRecommendation> recommendations,
  }) {
    final byWindowId = {
      for (final r in recommendations) r.window.id: r,
    };
    final payloads = <WindowNotificationPayload>[];
    for (final window in horse.timeWindows) {
      if (!window.notificationsEnabled) continue;
      final reco = byWindowId[window.id];
      if (reco == null) continue;
      payloads.add(
        WindowNotificationPayload(
          notificationId: notificationIdFor(
            horseId: horse.id,
            windowId: window.id,
          ),
          horseId: horse.id,
          windowId: window.id,
          horseName: horse.name,
          rangeLabel: window.labelRange,
          grams: reco.grams,
          confidence: reco.confidence,
          startHour: window.startMinutes ~/ 60,
          startMinute: window.startMinutes % 60,
        ),
      );
    }
    return payloads;
  }
}
