/// Où une pub peut apparaître. Un seul cooldown pour toutes les sources.
enum AdPlacement {
  /// Après un retour utilisateur (prioritaire).
  feedback,

  /// Au retour de la timeline (secondaire, plus rare).
  timeline,
}

/// Cooldown et tirage communs à AdMob (et aux tests).
abstract final class AdGate {
  static const prefsKey = 'bien_couvert_last_ad_ms';
  static const minInterval = Duration(minutes: 8);

  static int chancePercent(AdPlacement placement) => switch (placement) {
    AdPlacement.feedback => 35,
    AdPlacement.timeline => 20,
  };

  /// [roll] entre 0 et 99 inclus (`Random.nextInt(100)`).
  static bool shouldAttempt({
    required int nowMs,
    required int lastMs,
    required int roll,
    required AdPlacement placement,
  }) {
    if (nowMs - lastMs < minInterval.inMilliseconds) return false;
    return roll < chancePercent(placement);
  }
}
