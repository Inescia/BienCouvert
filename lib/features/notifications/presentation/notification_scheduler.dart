import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/presentation/providers.dart';
import '../../horses/domain/horse.dart';
import '../../recommendations/domain/recommendation_engine.dart';
import '../../recommendations/domain/window_recommendation.dart';
import '../data/notification_service.dart';
import '../domain/window_notification_planner.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  if (LocalNotificationService.isSupportedPlatform) {
    return LocalNotificationService();
  }
  return const NoOpNotificationService();
});

final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) {
  return NotificationScheduler(ref);
});

class NotificationScheduler {
  NotificationScheduler(this._ref);

  final Ref _ref;
  final _planner = const WindowNotificationPlanner();
  final _aggregator = const WindowRecommendationAggregator();

  Future<void> syncForHorse(Horse horse) async {
    final service = _ref.read(notificationServiceProvider);
    final needsPermission = horse.timeWindows.any(
      (w) => w.notificationsEnabled,
    );
    if (!needsPermission) {
      await service.cancelHorse(horse.id);
      return;
    }

    final granted = await service.requestPermission();
    if (!granted) {
      await service.cancelHorse(horse.id);
      return;
    }

    if (!horse.location.hasCoordinates) {
      await service.cancelHorse(horse.id);
      return;
    }

    final gramStep = _ref.read(settingsProvider).value?.gramStep ?? 50;
    final forecast = await _ref
        .read(cachedWeatherServiceProvider)
        .getForecast(horse.location);
    if (forecast.hours.isEmpty) {
      await service.cancelHorse(horse.id);
      return;
    }

    final timeline = _ref
        .read(recommendationEngineProvider)
        .calculate(
          horse: HorseProfile.fromHorse(horse),
          environment: const EnvironmentContext(),
          weather: forecast.hours,
          gramStep: gramStep,
        );

    final recos = _aggregator.forHorseWindows(
      windows: horse.timeWindows,
      hourly: timeline.hourly,
      weather: forecast.hours,
    );
    final payloads = _planner.plan(horse: horse, recommendations: recos);
    await service.syncHorseWindows(horseId: horse.id, payloads: payloads);
  }

  Future<void> syncAll() async {
    final horses = _ref.read(horsesProvider).value ?? const [];
    for (final horse in horses) {
      await syncForHorse(horse);
    }
  }
}
