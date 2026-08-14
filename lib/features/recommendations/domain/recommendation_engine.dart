import '../../horses/domain/horse.dart';
import '../../horses/domain/horse_enums.dart';
import '../../weather/domain/hourly_weather.dart';
import 'blanket_grams.dart';
import 'recommendation.dart';
import 'recommendation_rules.dart';

/// Profil minimal attendu par le moteur (extrait du Horse).
class HorseProfile {
  const HorseProfile({
    required this.clippingLevel,
    required this.coatThickness,
    required this.coldSensitivity,
    required this.housingType,
    required this.shelterAvailable,
    required this.bodyCondition,
    required this.activityLevel,
    required this.personalOffsetGrams,
  });

  factory HorseProfile.fromHorse(Horse horse) {
    return HorseProfile(
      clippingLevel: horse.clippingLevel,
      coatThickness: horse.coatThickness,
      coldSensitivity: horse.coldSensitivity,
      housingType: horse.housingType,
      shelterAvailable: horse.shelterAvailable,
      // Non saisis dans l’app : le moteur garde des décalages neutres.
      bodyCondition: BodyCondition.ideal,
      activityLevel: ActivityLevel.moderate,
      personalOffsetGrams: horse.personalAdjustment.offsetGrams,
    );
  }

  final ClippingLevel clippingLevel;
  final CoatThickness coatThickness;
  final double coldSensitivity;
  final HousingType housingType;
  final bool shelterAvailable;
  final BodyCondition bodyCondition;
  final ActivityLevel activityLevel;
  final int personalOffsetGrams;
}

class EnvironmentContext {
  const EnvironmentContext({this.isNightBoostEnabled = true});

  final bool isNightBoostEnabled;
}

/// Moteur pure Dart — aucune dépendance Flutter / IO.
class RecommendationEngine {
  RecommendationEngine({this.rules = RecommendationRules.standard});

  final RecommendationRules rules;

  RecommendationTimeline calculate({
    required HorseProfile horse,
    required EnvironmentContext environment,
    required List<HourlyWeather> weather,
    DateTime? generatedAt,
    int gramStep = 50,
  }) {
    assert(weather.isNotEmpty, 'Weather list must not be empty');

    final now = generatedAt ?? DateTime.now();
    final sorted = [...weather]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final hourly = sorted
        .map(
          (w) => _calculateHour(
            horse: horse,
            environment: environment,
            weather: w,
            gramStep: gramStep,
          ),
        )
        .toList();

    final periods = _collapsePeriods(hourly);

    return RecommendationTimeline(
      periods: periods,
      generatedAt: now,
      hourly: hourly,
    );
  }

  HourlyRecommendation _calculateHour({
    required HorseProfile horse,
    required EnvironmentContext environment,
    required HourlyWeather weather,
    int gramStep = 50,
  }) {
    final factors = <RecommendationFactor>[];
    var effectiveTemp = weather.temperature;

    final tempScore = rules.temperatureScore(effectiveTemp);
    factors.add(
      RecommendationFactor(
        kind: ReasonFactorKind.temperature,
        label: '${weather.temperature.round()}°C',
        contribution: tempScore,
      ),
    );

    effectiveTemp = _applyTempShift(
      previousTemp: effectiveTemp,
      shiftC: rules.clippingTempShift(horse.clippingLevel),
      kind: ReasonFactorKind.clipping,
      label: horse.clippingLevel.labelFr.toLowerCase(),
      factors: factors,
    );
    effectiveTemp = _applyTempShift(
      previousTemp: effectiveTemp,
      shiftC: rules.coatTempShift(horse.coatThickness),
      kind: ReasonFactorKind.coat,
      label: horse.coatThickness.labelFr.toLowerCase(),
      factors: factors,
    );
    effectiveTemp = _applyTempShift(
      previousTemp: effectiveTemp,
      shiftC: rules.sensitivityTempShift(horse.coldSensitivity),
      kind: ReasonFactorKind.coldSensitivity,
      label: horse.coldSensitivity >= 0.65
          ? 'cheval frileux'
          : horse.coldSensitivity <= 0.35
          ? 'peu frileux'
          : 'sensibilité normale',
      factors: factors,
    );
    effectiveTemp = _applyTempShift(
      previousTemp: effectiveTemp,
      shiftC: rules.bodyConditionTempShift(horse.bodyCondition),
      kind: ReasonFactorKind.coldSensitivity,
      label: horse.bodyCondition.labelFr.toLowerCase(),
      factors: factors,
    );
    effectiveTemp = _applyTempShift(
      previousTemp: effectiveTemp,
      shiftC: rules.activityTempShift(horse.activityLevel),
      kind: ReasonFactorKind.coldSensitivity,
      label: horse.activityLevel.labelFr.toLowerCase(),
      factors: factors,
    );
    effectiveTemp = _applyTempShift(
      previousTemp: effectiveTemp,
      shiftC: rules.housingTempShift(
        horse.housingType,
        shelterAvailable: horse.shelterAvailable,
      ),
      kind: ReasonFactorKind.housing,
      label: horse.housingType.labelFr.toLowerCase(),
      factors: factors,
    );

    if (environment.isNightBoostEnabled && _isNight(weather.timestamp)) {
      effectiveTemp = _applyTempShift(
        previousTemp: effectiveTemp,
        shiftC: rules.nightTempShift,
        kind: ReasonFactorKind.night,
        label: 'nuit',
        factors: factors,
      );
    }

    var score = rules.temperatureScore(effectiveTemp);
    final thermalScore = score;

    final windScore = _windScore(weather.windSpeed, weather.windGust);
    if (windScore > 0.25) {
      factors.add(
        RecommendationFactor(
          kind: ReasonFactorKind.wind,
          label: weather.windSpeed >= rules.thresholds.windStrongKmh
              ? 'vent fort'
              : 'vent soutenu',
          contribution: windScore,
        ),
      );
    }

    final humidityScore = _humidityScore(weather.humidity);
    if (humidityScore > 0.25) {
      factors.add(
        RecommendationFactor(
          kind: ReasonFactorKind.humidity,
          label: 'humidité élevée',
          contribution: humidityScore,
        ),
      );
    }

    final precipScore = _precipitationScore(weather);
    if (precipScore > 0.25) {
      factors.add(
        RecommendationFactor(
          kind: ReasonFactorKind.precipitation,
          label: weather.condition == WeatherCondition.snow
              ? 'neige'
              : weather.condition == WeatherCondition.heavyRain
              ? 'forte pluie'
              : 'pluie',
          contribution: precipScore,
        ),
      );
    }

    // Vent / pluie n'ajoutent du garnissage que si on est déjà dans
    // une couverture thermique. Sinon → imper 0 g, pas 50 g.
    if (thermalScore >= 1.0) {
      score += windScore + humidityScore + precipScore;
    }

    if (horse.personalOffsetGrams != 0) {
      final personalScore = horse.personalOffsetGrams / 50.0;
      score += personalScore;
      factors.add(
        RecommendationFactor(
          kind: ReasonFactorKind.personalAdjustment,
          label: horse.personalOffsetGrams > 0
              ? 'ajustement personnel (+${horse.personalOffsetGrams} g)'
              : 'ajustement personnel (${horse.personalOffsetGrams} g)',
          contribution: personalScore,
        ),
      );
    }

    score = score.clamp(0.0, 20.0);
    var grams = rules.gramsForScore(score).applyStep(gramStep);
    if (grams.isNone && rules.needsRainSheet(weather)) {
      grams = BlanketGrams.sheet;
    }
    // Même un gros offset perso ne doit pas couvrir trop chaud
    // (risque d'hyperthermie, Fletcher 2015 / IFCE).
    if (weather.temperature >= rules.thresholds.rainSheetMaxTempC &&
        grams.hasFill) {
      grams = BlanketGrams.none;
    }
    final confidence = _confidence(score: score, weather: weather);

    return HourlyRecommendation(
      start: weather.timestamp,
      grams: grams,
      score: score,
      reason: RecommendationReason(
        summary: _buildSummary(grams, factors, weather),
        factors: factors,
        confidence: confidence,
      ),
      weatherTimestamp: weather.timestamp,
    );
  }

  double _applyTempShift({
    required double previousTemp,
    required double shiftC,
    required ReasonFactorKind kind,
    required String label,
    required List<RecommendationFactor> factors,
  }) {
    if (shiftC.abs() < 0.05) return previousTemp;
    final nextTemp = previousTemp - shiftC;
    final contribution =
        rules.temperatureScore(nextTemp) - rules.temperatureScore(previousTemp);
    if (contribution.abs() >= 0.2) {
      factors.add(
        RecommendationFactor(
          kind: kind,
          label: label,
          contribution: contribution,
        ),
      );
    }
    return nextTemp;
  }

  double _windScore(double windSpeed, double windGust) {
    final effective = windSpeed > windGust
        ? windSpeed
        : (windSpeed * 0.7 + windGust * 0.3);
    final t = rules.thresholds;
    if (effective < t.windMildKmh) return 0;
    if (effective < t.windStrongKmh) {
      return ((effective - t.windMildKmh) / (t.windStrongKmh - t.windMildKmh)) *
          1.0 *
          rules.weights.windScale;
    }
    return (1.0 + ((effective - t.windStrongKmh) / 25.0).clamp(0.0, 1.0)) *
        rules.weights.windScale;
  }

  double _humidityScore(double humidity) {
    if (humidity < rules.thresholds.humidityHigh) return 0;
    return ((humidity - rules.thresholds.humidityHigh) / 20.0).clamp(0.0, 1.0) *
        0.6 *
        rules.weights.humidityScale;
  }

  double _precipitationScore(HourlyWeather weather) {
    var score = 0.0;
    if (weather.precipitation >= rules.thresholds.precipHeavyMm ||
        weather.condition == WeatherCondition.heavyRain) {
      score = 1.5;
    } else if (weather.precipitation >= rules.thresholds.precipLightMm ||
        weather.condition == WeatherCondition.rain) {
      score = 1.0;
    } else if (weather.condition == WeatherCondition.snow) {
      score = 1.5;
    } else if (weather.precipitationProbability >= 70) {
      score = 0.5;
    }
    if (score > 0 && weather.temperature < 8) {
      score += 0.5;
    }
    return score * rules.weights.precipitationScale;
  }

  bool _isNight(DateTime time) {
    final hour = time.hour;
    return hour >= 20 || hour < 7;
  }

  ConfidenceLevel _confidence({
    required double score,
    required HourlyWeather weather,
  }) {
    final extremeTemp = weather.temperature < -8 || weather.temperature > 28;
    final extremeWind = weather.windGust > 50;
    final heavyPrecip = weather.precipitation > 5;
    if (extremeTemp || extremeWind || heavyPrecip) {
      return ConfidenceLevel.unusual;
    }
    if (weather.precipitationProbability > 60 &&
        weather.precipitation < rules.thresholds.precipLightMm) {
      return ConfidenceLevel.watch;
    }
    return ConfidenceLevel.reliable;
  }

  String _buildSummary(
    BlanketGrams grams,
    List<RecommendationFactor> factors,
    HourlyWeather weather,
  ) {
    final notable = [...factors]
      ..sort((a, b) => b.contribution.abs().compareTo(a.contribution.abs()));
    final parts = notable
        .where((f) => f.contribution.abs() >= 0.8)
        .take(3)
        .map((f) => f.label)
        .toList();
    if (parts.isEmpty) {
      return '${grams.label} · ${weather.temperature.round()}°C';
    }
    return '${grams.label} · ${parts.join(' · ')}';
  }

  List<RecommendationPeriod> _collapsePeriods(
    List<HourlyRecommendation> hourly,
  ) {
    if (hourly.isEmpty) return const [];

    final periods = <RecommendationPeriod>[];
    var periodStart = hourly.first.start;
    var currentGrams = hourly.first.grams;
    var currentReason = hourly.first.reason;
    var currentScore = hourly.first.score;
    var lastEnd = hourly.first.start.add(const Duration(hours: 1));

    for (var i = 1; i < hourly.length; i++) {
      final h = hourly[i];
      final sameDay = _sameCalendarDay(h.start, periodStart);
      if (h.grams == currentGrams && sameDay) {
        lastEnd = h.start.add(const Duration(hours: 1));
        // Garde la raison la plus "forte" de la période.
        if (h.score > currentScore) {
          currentScore = h.score;
          currentReason = h.reason;
        }
      } else {
        periods.add(
          RecommendationPeriod(
            start: periodStart,
            end: lastEnd,
            grams: currentGrams,
            reason: currentReason,
            representativeScore: currentScore,
          ),
        );
        periodStart = h.start;
        currentGrams = h.grams;
        currentReason = h.reason;
        currentScore = h.score;
        lastEnd = h.start.add(const Duration(hours: 1));
      }
    }

    periods.add(
      RecommendationPeriod(
        start: periodStart,
        end: lastEnd,
        grams: currentGrams,
        reason: currentReason,
        representativeScore: currentScore,
      ),
    );

    return periods;
  }

  bool _sameCalendarDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
