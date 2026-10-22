import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/json_codec.dart';

/// Plage horaire saisie par l'utilisateur (max 5 par cheval).
///
/// Si [endMinutes] <= [startMinutes], la plage traverse minuit
/// (ex. 18:00 → 08:00).
class HorseTimeWindow extends Equatable {
  const HorseTimeWindow({
    required this.id,
    required this.startMinutes,
    required this.endMinutes,
    this.notificationsEnabled = false,
  });

  static const maxPerHorse = 5;
  static const _minutesPerDay = 24 * 60;

  final String id;

  /// Minutes depuis minuit [0, 1439].
  final int startMinutes;

  /// Minutes depuis minuit [0, 1439], exclusive côté agrégation horaire
  /// mais affichée comme heure de fin saisie (ex. 08:00).
  final int endMinutes;

  final bool notificationsEnabled;

  bool get crossesMidnight => endMinutes <= startMinutes;

  Duration get duration {
    if (crossesMidnight) {
      return Duration(minutes: _minutesPerDay - startMinutes + endMinutes);
    }
    return Duration(minutes: endMinutes - startMinutes);
  }

  String get labelRange {
    return '${_formatMinutes(startMinutes)} → ${_formatMinutes(endMinutes)}';
  }

  HorseTimeWindow copyWith({
    String? id,
    int? startMinutes,
    int? endMinutes,
    bool? notificationsEnabled,
  }) {
    return HorseTimeWindow(
      id: id ?? this.id,
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
      notificationsEnabled:
          notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'startMinutes': startMinutes,
    'endMinutes': endMinutes,
    'notificationsEnabled': notificationsEnabled,
  };

  factory HorseTimeWindow.fromJson(Map<String, dynamic> json) {
    final id = jsonString(json['id']) ?? const Uuid().v4();
    return HorseTimeWindow(
      id: id,
      startMinutes: _clampMinutes(jsonInt(json['startMinutes']) ?? 7 * 60 + 30),
      endMinutes: _clampMinutes(jsonInt(json['endMinutes']) ?? 9 * 60),
      notificationsEnabled: jsonBool(json['notificationsEnabled']),
    );
  }

  factory HorseTimeWindow.create({
    required int startMinutes,
    required int endMinutes,
    bool notificationsEnabled = false,
  }) {
    return HorseTimeWindow(
      id: const Uuid().v4(),
      startMinutes: _clampMinutes(startMinutes),
      endMinutes: _clampMinutes(endMinutes),
      notificationsEnabled: notificationsEnabled,
    );
  }

  /// Occurrence ancrée sur le jour calendaire de [day].
  ({DateTime start, DateTime end}) occurrenceOnDay(DateTime day) {
    final day0 = DateTime(day.year, day.month, day.day);
    final start = day0.add(Duration(minutes: startMinutes));
    final end = crossesMidnight
        ? day0.add(Duration(days: 1, minutes: endMinutes))
        : day0.add(Duration(minutes: endMinutes));
    return (start: start, end: end);
  }

  /// Prochaine occurrence (en cours ou à venir) par rapport à [now].
  ({DateTime start, DateTime end}) nextOccurrence(DateTime now) {
    final today = occurrenceOnDay(now);
    if (now.isBefore(today.end)) return today;
    return occurrenceOnDay(now.add(const Duration(days: 1)));
  }

  bool contains(DateTime instant) {
    final today = occurrenceOnDay(instant);
    if (!instant.isBefore(today.start) && instant.isBefore(today.end)) {
      return true;
    }
    final yesterday = occurrenceOnDay(
      instant.subtract(const Duration(days: 1)),
    );
    return !instant.isBefore(yesterday.start) &&
        instant.isBefore(yesterday.end);
  }

  static int _clampMinutes(int value) => value.clamp(0, _minutesPerDay - 1);

  static String _formatMinutes(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return m == '00' ? '${h}h' : '${h}h$m';
  }

  @override
  List<Object?> get props => [
    id,
    startMinutes,
    endMinutes,
    notificationsEnabled,
  ];
}
