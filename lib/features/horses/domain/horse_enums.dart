enum ClippingLevel {
  none,
  light,
  partial,
  heavy,
  full;

  String get labelFr => switch (this) {
    ClippingLevel.none => 'Pas tondu',
    ClippingLevel.light => 'Tonte légère',
    ClippingLevel.partial => 'Tonte partielle',
    ClippingLevel.heavy => 'Tonte importante',
    ClippingLevel.full => 'Entièrement tondu',
  };
}

enum CoatThickness {
  thin,
  medium,
  thick;

  String get labelFr => switch (this) {
    CoatThickness.thin => 'Poil fin',
    CoatThickness.medium => 'Poil moyen',
    CoatThickness.thick => 'Poil épais',
  };
}

enum BodyCondition {
  underweight,
  ideal,
  overweight;

  String get labelFr => switch (this) {
    BodyCondition.underweight => 'Un peu maigre',
    BodyCondition.ideal => 'État idéal',
    BodyCondition.overweight => 'Un peu fort',
  };
}

enum ActivityLevel {
  low,
  moderate,
  high;

  String get labelFr => switch (this) {
    ActivityLevel.low => 'Peu actif',
    ActivityLevel.moderate => 'Activité normale',
    ActivityLevel.high => 'Très actif',
  };
}

enum HousingType {
  closedBox,
  boxWithOpening,
  openStable,
  paddock,
  field,
  fieldWithShelter;

  String get labelFr => switch (this) {
    HousingType.closedBox => 'Box fermé',
    HousingType.boxWithOpening => 'Box avec ouverture',
    HousingType.openStable => 'Écurie ouverte',
    HousingType.paddock => 'Paddock',
    HousingType.field => 'Pré',
    HousingType.fieldWithShelter => 'Pré avec abri',
  };

  /// 0 = abrité, 1 = très exposé.
  double get exposureFactor => switch (this) {
    HousingType.closedBox => 0.15,
    HousingType.boxWithOpening => 0.35,
    HousingType.openStable => 0.55,
    HousingType.paddock => 0.85,
    HousingType.field => 1.0,
    HousingType.fieldWithShelter => 0.7,
  };
}

enum WeatherCondition {
  clear,
  partlyCloudy,
  cloudy,
  rain,
  heavyRain,
  snow,
  fog,
  windy;

  String get labelFr => switch (this) {
    WeatherCondition.clear => 'Clair',
    WeatherCondition.partlyCloudy => 'Peu nuageux',
    WeatherCondition.cloudy => 'Couvert',
    WeatherCondition.rain => 'Pluie',
    WeatherCondition.heavyRain => 'Forte pluie',
    WeatherCondition.snow => 'Neige',
    WeatherCondition.fog => 'Brouillard',
    WeatherCondition.windy => 'Venteux',
  };
}

enum FeedbackFeeling {
  tooCold,
  perfect,
  tooWarm;

  String get labelFr => switch (this) {
    FeedbackFeeling.tooCold => 'Trop froid',
    FeedbackFeeling.perfect => 'Parfait',
    FeedbackFeeling.tooWarm => 'Trop chaud',
  };

  String get emoji => switch (this) {
    FeedbackFeeling.tooCold => '🥶',
    FeedbackFeeling.perfect => '🙂',
    FeedbackFeeling.tooWarm => '🥵',
  };
}

enum PreferredAdjustment {
  warmer,
  lighter;

  String get labelFr => switch (this) {
    PreferredAdjustment.warmer => 'Plus chaud',
    PreferredAdjustment.lighter => 'Plus léger',
  };
}

enum WeatherFreshness { fresh, cached, stale, unavailable }

enum ConfidenceLevel {
  reliable,
  watch,
  unusual;

  String get labelFr => switch (this) {
    ConfidenceLevel.reliable => 'Recommandation fiable',
    ConfidenceLevel.watch => 'À surveiller',
    ConfidenceLevel.unusual => 'Conditions inhabituelles — à surveiller',
  };
}
