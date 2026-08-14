import 'package:intl/intl.dart';

String greetingForNow([DateTime? now]) {
  final hour = (now ?? DateTime.now()).hour;
  if (hour < 12) return 'Bonjour';
  if (hour < 18) return 'Bon après-midi';
  return 'Bonsoir';
}

String formatHour(DateTime dt) => DateFormat('HH\'h\'').format(dt);

String formatForecastDayLabel(DateTime date, [DateTime? now]) {
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  final day = DateTime(date.year, date.month, date.day);
  final diff = day.difference(today).inDays;
  return switch (diff) {
    0 => 'Aujourd\'hui',
    1 => 'Demain',
    2 => 'Après-demain',
    _ => DateFormat('d/MM').format(date),
  };
}

String formatHourShort(DateTime dt) => DateFormat('HH:mm').format(dt);

String formatRelativeAge(DateTime fetchedAt, [DateTime? now]) {
  final age = (now ?? DateTime.now()).difference(fetchedAt);
  if (age.inMinutes < 1) return 'à l\'instant';
  if (age.inMinutes < 60) return 'il y a ${age.inMinutes} min';
  if (age.inHours < 24) return 'il y a ${age.inHours} h';
  return 'il y a ${age.inDays} j';
}

String coldSensitivityLabel(double value) {
  if (value <= 0.25) return 'Très peu frileux';
  if (value <= 0.45) return 'Peu frileux';
  if (value <= 0.55) return 'Normal';
  if (value <= 0.75) return 'Frileux';
  return 'Très frileux';
}
