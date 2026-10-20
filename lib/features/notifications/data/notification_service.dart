import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../domain/window_notification_payload.dart';

/// Planifie / annule les rappels locaux de plages.
abstract class NotificationService {
  Future<void> initialize();
  Future<bool> requestPermission();
  Future<void> syncHorseWindows({
    required String horseId,
    required List<WindowNotificationPayload> payloads,
  });
  Future<void> cancelHorse(String horseId);
}

class NoOpNotificationService implements NotificationService {
  const NoOpNotificationService();

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> syncHorseWindows({
    required String horseId,
    required List<WindowNotificationPayload> payloads,
  }) async {}

  @override
  Future<void> cancelHorse(String horseId) async {}
}

class LocalNotificationService implements NotificationService {
  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;
  final Set<String> _knownHorseIds = {};

  static bool get isSupportedPlatform {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
  }

  @override
  Future<void> initialize() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios, macOS: ios),
    );
    _ready = true;
  }

  @override
  Future<bool> requestPermission() async {
    await initialize();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final macos = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();

    var granted = true;
    if (android != null) {
      granted = await android.requestNotificationsPermission() ?? false;
    }
    if (ios != null) {
      granted =
          await ios.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    }
    if (macos != null) {
      granted =
          await macos.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return granted;
  }

  @override
  Future<void> syncHorseWindows({
    required String horseId,
    required List<WindowNotificationPayload> payloads,
  }) async {
    await initialize();
    await cancelHorse(horseId);
    _knownHorseIds.add(horseId);
    for (final payload in payloads) {
      await _scheduleDaily(payload);
    }
  }

  @override
  Future<void> cancelHorse(String horseId) async {
    await initialize();
    final pending = await _plugin.pendingNotificationRequests();
    for (final req in pending) {
      final payload = req.payload;
      if (payload != null && payload.startsWith('$horseId|')) {
        await _plugin.cancel(req.id);
      }
    }
  }

  Future<void> _scheduleDaily(WindowNotificationPayload payload) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      payload.startHour,
      payload.startMinute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'plages_couverture',
      'Plages de couverture',
      channelDescription:
          'Rappels au début de tes plages horaires de couverture',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      payload.notificationId,
      payload.title,
      payload.body,
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: '${payload.horseId}|${payload.windowId}',
    );
  }
}
