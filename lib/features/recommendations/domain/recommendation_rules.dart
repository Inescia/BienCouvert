import '../../horses/domain/horse_enums.dart';
import '../../weather/domain/hourly_weather.dart';
import 'blanket_grams.dart';

/// Coefficients et seuils centralisés — pas de magic numbers dispersés.
///
/// Paliers de référence (cheval non tondu, sensibilité et humidité normales) :
/// - dès 10 °C au sec : pas de couverture
/// - pluie / vent vers 10–18 °C : imper 0 g
/// - vers 5 °C : 100 g
/// - sous 0 °C : 200 g
/// Un cheval entièrement tondu est décalé d'environ 5 °C.
///
/// Sources : IFCE Equipedia (zone de confort ~5–25 °C, Morgan 1998 ;
/// tonte : TCI plus proche de 5 °C que de −15 °C ; Fletcher 2015 : imper
/// au-delà de 20 °C → hyperthermie) ; UK Extension ASC-240 (sheet 0 g).
class RecommendationWeights {
  const RecommendationWeights({
    this.temperatureScale = 1.0,
    this.windScale = 1.0,
    this.humidityScale = 1.0,
    this.precipitationScale = 1.0,
    this.clippingScale = 1.0,
    this.coatScale = 1.0,
    this.sensitivityScale = 1.0,
    this.housingScale = 1.0,
  });

  final double temperatureScale;
  final double windScale;
  final double humidityScale;
  final double precipitationScale;
  final double clippingScale;
  final double coatScale;
  final double sensitivityScale;
  final double housingScale;

  static const standard = RecommendationWeights();
}

class RecommendationThresholds {
  const RecommendationThresholds({
    this.comfortableTempC = 10.0,
    this.lightBlanketTempC = 5.0,
    this.mediumBlanketTempC = 0.0,
    this.windMildKmh = 15.0,
    this.windStrongKmh = 30.0,
    this.humidityHigh = 80.0,
    this.precipLightMm = 0.2,
    this.precipHeavyMm = 2.0,
    this.unusualScoreDelta = 8.0,
    this.gramsPerDegreeC = 20.0,
    this.rainSheetMaxTempC = 18.0,
  });

  /// Au-dessus : pas de couverture pour un non-tondu de référence.
  final double comfortableTempC;

  /// Environ 100 g pour un non-tondu de référence.
  final double lightBlanketTempC;

  /// Environ 200 g pour un non-tondu de référence.
  final double mediumBlanketTempC;

  final double windMildKmh;
  final double windStrongKmh;
  final double humidityHigh;
  final double precipLightMm;
  final double precipHeavyMm;
  final double unusualScoreDelta;

  /// 5 °C × 20 g = 100 g, 10 °C × 20 g = 200 g.
  final double gramsPerDegreeC;

  /// Au-delà, une imper risque l'hyperthermie (Fletcher 2015 / IFCE).
  final double rainSheetMaxTempC;

  static const standard = RecommendationThresholds();
}

class RecommendationRules {
  const RecommendationRules({
    this.weights = RecommendationWeights.standard,
    this.thresholds = RecommendationThresholds.standard,
    this.scoreToGrams = const [
      (0.0, BlanketGrams.none),
      (1.0, BlanketGrams.g50),
      (2.0, BlanketGrams.g100),
      (3.0, BlanketGrams.g150),
      (4.0, BlanketGrams.g200),
      (5.0, BlanketGrams.g250),
      (6.0, BlanketGrams.g300),
      (7.0, BlanketGrams.g350),
      (8.0, BlanketGrams.g400),
    ],
  });

  final RecommendationWeights weights;
  final RecommendationThresholds thresholds;
  final List<(double minScore, BlanketGrams grams)> scoreToGrams;

  static const standard = RecommendationRules();

  /// 1,0 point de score = 50 g.
  double get scorePerDegreeC => thresholds.gramsPerDegreeC / 50.0;

  BlanketGrams gramsForScore(double score) {
    var result = BlanketGrams.none;
    for (final entry in scoreToGrams) {
      if (score >= entry.$1) {
        result = entry.$2;
      }
    }
    return result;
  }

  /// Imper 0 g : pluie, neige ou vent fort, tant qu'il ne fait pas trop chaud.
  bool needsRainSheet(HourlyWeather weather) {
    if (weather.temperature >= thresholds.rainSheetMaxTempC) return false;
    final wet =
        weather.precipitation >= thresholds.precipLightMm ||
        weather.condition == WeatherCondition.rain ||
        weather.condition == WeatherCondition.heavyRain ||
        weather.condition == WeatherCondition.snow ||
        weather.precipitationProbability >= 70;
    final windy =
        weather.windSpeed >= thresholds.windStrongKmh ||
        weather.windGust >= thresholds.windStrongKmh;
    return wet || windy;
  }

  double temperatureScore(double tempC) {
    if (tempC >= thresholds.comfortableTempC) return 0;
    final score =
        (thresholds.comfortableTempC - tempC) *
        scorePerDegreeC *
        weights.temperatureScale;
    return score.clamp(0.0, 8.0).toDouble();
  }

  /// Décalage en °C : tonte complète ≈ +5 °C de froid ressenti.
  double clippingTempShift(ClippingLevel level) {
    final base = switch (level) {
      ClippingLevel.none => 0.0,
      ClippingLevel.light => 1.5,
      ClippingLevel.partial => 3.0,
      ClippingLevel.heavy => 4.0,
      ClippingLevel.full => 5.0,
    };
    return base * weights.clippingScale;
  }

  double coatTempShift(CoatThickness coat) {
    final base = switch (coat) {
      CoatThickness.thin => 2.0,
      CoatThickness.medium => 0.0,
      CoatThickness.thick => -2.0,
    };
    return base * weights.coatScale;
  }

  double sensitivityTempShift(double coldSensitivity) {
    return ((coldSensitivity - 0.5) * 10.0) * weights.sensitivityScale;
  }

  /// Référence = pré avec abri. Positif = plus exposé (plus de couverture).
  double housingTempShift(
    HousingType housing, {
    required bool shelterAvailable,
  }) {
    var shift = switch (housing) {
      HousingType.closedBox => -3.0,
      HousingType.boxWithOpening => -2.0,
      HousingType.openStable => -1.0,
      HousingType.fieldWithShelter => 0.0,
      HousingType.paddock => 1.0,
      HousingType.field => 2.0,
    };
    if (shelterAvailable &&
        (housing == HousingType.field || housing == HousingType.paddock)) {
      shift -= 1.0;
    }
    return shift * weights.housingScale;
  }

  double bodyConditionTempShift(BodyCondition condition) {
    return switch (condition) {
      BodyCondition.underweight => 2.0,
      BodyCondition.ideal => 0.0,
      BodyCondition.overweight => -1.0,
    };
  }

  double activityTempShift(ActivityLevel activity) {
    return switch (activity) {
      ActivityLevel.low => 1.0,
      ActivityLevel.moderate => 0.0,
      ActivityLevel.high => -1.0,
    };
  }

  double get nightTempShift => 2.0;
}
