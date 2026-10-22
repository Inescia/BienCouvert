import 'package:equatable/equatable.dart';

import '../../horses/domain/horse_enums.dart';
import '../../recommendations/domain/blanket_grams.dart';

/// Contenu d'une notif planifiée pour une plage.
class WindowNotificationPayload extends Equatable {
  const WindowNotificationPayload({
    required this.notificationId,
    required this.horseId,
    required this.windowId,
    required this.horseName,
    required this.rangeLabel,
    required this.grams,
    required this.confidence,
    required this.startHour,
    required this.startMinute,
  });

  final int notificationId;
  final String horseId;
  final String windowId;
  final String horseName;
  final String rangeLabel;
  final BlanketGrams grams;
  final ConfidenceLevel confidence;
  final int startHour;
  final int startMinute;

  String get title => 'Bien Couvert · $horseName';

  String get body =>
      '$rangeLabel · ${grams.label} · ${confidence.labelFr}';

  @override
  List<Object?> get props => [
    notificationId,
    horseId,
    windowId,
    horseName,
    rangeLabel,
    grams,
    confidence,
    startHour,
    startMinute,
  ];
}

/// Identifiant stable (31 bits) pour flutter_local_notifications.
int notificationIdFor({
  required String horseId,
  required String windowId,
}) {
  return Object.hash(horseId, windowId) & 0x7fffffff;
}
