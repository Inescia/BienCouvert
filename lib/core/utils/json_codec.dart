/// Lecture JSON défensive — évite les casts qui font planter le démarrage.
T enumByName<T extends Enum>(List<T> values, Object? raw, T fallback) {
  if (raw is! String) return fallback;
  for (final value in values) {
    if (value.name == raw) return value;
  }
  return fallback;
}

String? jsonString(Object? raw) {
  if (raw is String) {
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  return raw?.toString();
}

int? jsonInt(Object? raw) {
  if (raw is int) return raw;
  if (raw is num) return raw.round();
  if (raw is String) return int.tryParse(raw);
  return null;
}

double? jsonDouble(Object? raw) {
  if (raw is num) return raw.toDouble();
  if (raw is String) return double.tryParse(raw);
  return null;
}

bool jsonBool(Object? raw, {bool fallback = false}) {
  if (raw is bool) return raw;
  return fallback;
}

Map<String, dynamic>? jsonMap(Object? raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return null;
}

List<Map<String, dynamic>> jsonMapList(Object? raw) {
  if (raw is! List) return const [];
  final items = <Map<String, dynamic>>[];
  for (final entry in raw) {
    final map = jsonMap(entry);
    if (map != null) items.add(map);
  }
  return items;
}

DateTime jsonDate(Object? raw) {
  if (raw is String) {
    return DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}
