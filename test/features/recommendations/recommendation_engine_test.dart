import 'package:flutter_test/flutter_test.dart';
import 'package:poney_au_chaud/features/horses/domain/horse_enums.dart';
import 'package:poney_au_chaud/features/recommendations/domain/blanket_grams.dart';
import 'package:poney_au_chaud/features/recommendations/domain/recommendation_engine.dart';
import 'package:poney_au_chaud/features/weather/domain/hourly_weather.dart';

HourlyWeather _w({
  required DateTime timestamp,
  required double temp,
  double wind = 5,
  double humidity = 60,
  double precip = 0,
  WeatherCondition condition = WeatherCondition.clear,
}) {
  return HourlyWeather(
    timestamp: timestamp,
    temperature: temp,
    feelsLike: temp - wind / 20,
    humidity: humidity,
    windSpeed: wind,
    windGust: wind + 3,
    precipitation: precip,
    precipitationProbability: precip > 0 ? 80 : 10,
    condition: condition,
  );
}

HorseProfile _horse({
  ClippingLevel clipping = ClippingLevel.none,
  CoatThickness coat = CoatThickness.medium,
  double sensitivity = 0.5,
  HousingType housing = HousingType.fieldWithShelter,
  bool shelter = true,
  int offset = 0,
}) {
  return HorseProfile(
    clippingLevel: clipping,
    coatThickness: coat,
    coldSensitivity: sensitivity,
    housingType: housing,
    shelterAvailable: shelter,
    bodyCondition: BodyCondition.ideal,
    activityLevel: ActivityLevel.moderate,
    personalOffsetGrams: offset,
  );
}

void main() {
  late RecommendationEngine engine;
  final base = DateTime(2026, 1, 15, 18);

  setUp(() {
    engine = RecommendationEngine();
  });

  group('RecommendationEngine', () {
    BlanketGrams recoFor({
      required double temp,
      ClippingLevel clipping = ClippingLevel.none,
      double sensitivity = 0.5,
      HousingType housing = HousingType.fieldWithShelter,
      bool shelter = true,
      double humidity = 60,
      double wind = 5,
      double precip = 0,
      WeatherCondition condition = WeatherCondition.clear,
    }) {
      final time = DateTime(2026, 1, 15, 14);
      return engine
          .calculate(
            horse: _horse(
              clipping: clipping,
              sensitivity: sensitivity,
              housing: housing,
              shelter: shelter,
            ),
            environment: const EnvironmentContext(),
            weather: [
              _w(
                timestamp: time,
                temp: temp,
                humidity: humidity,
                wind: wind,
                precip: precip,
                condition: condition,
              ),
            ],
            generatedAt: time,
          )
          .periods
          .first
          .grams;
    }

    int gramsFor({
      required double temp,
      ClippingLevel clipping = ClippingLevel.none,
      double sensitivity = 0.5,
      HousingType housing = HousingType.fieldWithShelter,
      bool shelter = true,
      double humidity = 60,
      double wind = 5,
    }) {
      return recoFor(
        temp: temp,
        clipping: clipping,
        sensitivity: sensitivity,
        housing: housing,
        shelter: shelter,
        humidity: humidity,
        wind: wind,
      ).value;
    }

    test('non tondu dès 10 °C au sec → pas de couverture', () {
      expect(recoFor(temp: 10), BlanketGrams.none);
      expect(recoFor(temp: 12), BlanketGrams.none);
    });

    test('pluie vers 12 °C → imper 0 g, pas du vide', () {
      expect(
        recoFor(temp: 12, precip: 1, condition: WeatherCondition.rain),
        BlanketGrams.sheet,
      );
      expect(recoFor(temp: 12), BlanketGrams.none);
    });

    test('vent fort vers 12 °C → imper 0 g', () {
      expect(recoFor(temp: 12, wind: 35), BlanketGrams.sheet);
    });

    test('pluie au-dessus de 18 °C → pas d\'imper', () {
      expect(
        recoFor(temp: 22, precip: 2, condition: WeatherCondition.rain),
        BlanketGrams.none,
      );
    });

    test('pluie vers 5 °C → garnissage, pas seulement l\'imper', () {
      expect(
        recoFor(
          temp: 5,
          precip: 2.5,
          condition: WeatherCondition.heavyRain,
        ).hasFill,
        isTrue,
      );
    });

    test('non tondu vers 5 °C, humidité normale → 100 g', () {
      expect(gramsFor(temp: 5), 100);
    });

    test('non tondu sous 0 °C → 200 g', () {
      expect(gramsFor(temp: -1), 200);
    });

    test('tonte complète décale d\'environ 5 °C', () {
      expect(gramsFor(temp: 10, clipping: ClippingLevel.full), 100);
      expect(gramsFor(temp: 5, clipping: ClippingLevel.full), 200);
      expect(gramsFor(temp: 15, clipping: ClippingLevel.full), 0);
    });

    test('frileux encore couvert vers 10 °C', () {
      expect(gramsFor(temp: 10, sensitivity: 0.9), greaterThan(0));
      expect(gramsFor(temp: 10), 0);
    });

    test('température élevée → grammage bas', () {
      final timeline = engine.calculate(
        horse: _horse(housing: HousingType.closedBox),
        environment: const EnvironmentContext(),
        weather: [_w(timestamp: base, temp: 18)],
        generatedAt: base,
      );
      expect(timeline.periods.first.grams.value, lessThanOrEqualTo(100));
    });

    test('température basse → grammage élevé', () {
      final timeline = engine.calculate(
        horse: _horse(),
        environment: const EnvironmentContext(),
        weather: [_w(timestamp: base, temp: -2)],
        generatedAt: base,
      );
      expect(timeline.periods.first.grams.value, greaterThanOrEqualTo(200));
    });

    test('vent fort augmente la recommandation', () {
      final calm = engine.calculate(
        horse: _horse(),
        environment: const EnvironmentContext(),
        weather: [_w(timestamp: base, temp: 6, wind: 5)],
        generatedAt: base,
      );
      final windy = engine.calculate(
        horse: _horse(),
        environment: const EnvironmentContext(),
        weather: [_w(timestamp: base, temp: 6, wind: 40)],
        generatedAt: base,
      );
      expect(
        windy.periods.first.grams.value,
        greaterThanOrEqualTo(calm.periods.first.grams.value),
      );
    });

    test('pluie froide augmente la recommandation', () {
      final dry = engine.calculate(
        horse: _horse(),
        environment: const EnvironmentContext(),
        weather: [_w(timestamp: base, temp: 5)],
        generatedAt: base,
      );
      final rain = engine.calculate(
        horse: _horse(),
        environment: const EnvironmentContext(),
        weather: [
          _w(
            timestamp: base,
            temp: 5,
            precip: 2.5,
            condition: WeatherCondition.heavyRain,
          ),
        ],
        generatedAt: base,
      );
      expect(
        rain.periods.first.grams.value,
        greaterThan(dry.periods.first.grams.value),
      );
    });

    test('humidité élevée augmente légèrement', () {
      final dry = engine.calculate(
        horse: _horse(),
        environment: const EnvironmentContext(),
        weather: [_w(timestamp: base, temp: 5, humidity: 50)],
        generatedAt: base,
      );
      final humid = engine.calculate(
        horse: _horse(),
        environment: const EnvironmentContext(),
        weather: [_w(timestamp: base, temp: 5, humidity: 95)],
        generatedAt: base,
      );
      expect(humid.hourly.first.score, greaterThan(dry.hourly.first.score));
    });

    test('cheval tondu > cheval non tondu', () {
      final natural = engine.calculate(
        horse: _horse(clipping: ClippingLevel.none),
        environment: const EnvironmentContext(),
        weather: [_w(timestamp: base, temp: 5)],
        generatedAt: base,
      );
      final clipped = engine.calculate(
        horse: _horse(clipping: ClippingLevel.full),
        environment: const EnvironmentContext(),
        weather: [_w(timestamp: base, temp: 5)],
        generatedAt: base,
      );
      expect(
        clipped.periods.first.grams.value,
        greaterThan(natural.periods.first.grams.value),
      );
    });

    test('cheval frileux > peu frileux', () {
      final hardy = engine.calculate(
        horse: _horse(sensitivity: 0.1),
        environment: const EnvironmentContext(),
        weather: [_w(timestamp: base, temp: 5)],
        generatedAt: base,
      );
      final chilly = engine.calculate(
        horse: _horse(sensitivity: 0.95),
        environment: const EnvironmentContext(),
        weather: [_w(timestamp: base, temp: 5)],
        generatedAt: base,
      );
      expect(
        chilly.periods.first.grams.value,
        greaterThanOrEqualTo(hardy.periods.first.grams.value),
      );
    });

    test('pré plus exposé que box fermé', () {
      final box = engine.calculate(
        horse: _horse(housing: HousingType.closedBox),
        environment: const EnvironmentContext(),
        weather: [_w(timestamp: base, temp: 5, wind: 25)],
        generatedAt: base,
      );
      final field = engine.calculate(
        horse: _horse(housing: HousingType.field, shelter: false),
        environment: const EnvironmentContext(),
        weather: [_w(timestamp: base, temp: 5, wind: 25)],
        generatedAt: base,
      );
      expect(
        field.periods.first.grams.value,
        greaterThanOrEqualTo(box.periods.first.grams.value),
      );
    });

    test('pré avec abri un peu moins exposé que pré nu', () {
      final open = engine.calculate(
        horse: _horse(housing: HousingType.field, shelter: false),
        environment: const EnvironmentContext(),
        weather: [_w(timestamp: base, temp: 4, wind: 20)],
        generatedAt: base,
      );
      final sheltered = engine.calculate(
        horse: _horse(housing: HousingType.fieldWithShelter, shelter: true),
        environment: const EnvironmentContext(),
        weather: [_w(timestamp: base, temp: 4, wind: 20)],
        generatedAt: base,
      );
      expect(
        open.hourly.first.score,
        greaterThanOrEqualTo(sheltered.hourly.first.score),
      );
    });

    test('scénario combiné froid + vent + pluie + tondu + frileux', () {
      final timeline = engine.calculate(
        horse: _horse(
          clipping: ClippingLevel.full,
          sensitivity: 0.9,
          housing: HousingType.field,
          shelter: false,
        ),
        environment: const EnvironmentContext(),
        weather: [
          _w(
            timestamp: base,
            temp: 5,
            wind: 35,
            humidity: 90,
            precip: 2,
            condition: WeatherCondition.rain,
          ),
        ],
        generatedAt: base,
      );
      expect(timeline.periods.first.grams.value, greaterThanOrEqualTo(300));
      expect(timeline.periods.first.reason.factors, isNotEmpty);
    });

    test('collapse des périodes identiques', () {
      final weather = List.generate(6, (i) {
        return _w(timestamp: base.add(Duration(hours: i)), temp: 8, wind: 10);
      });
      final timeline = engine.calculate(
        horse: _horse(),
        environment: const EnvironmentContext(),
        weather: weather,
        generatedAt: base,
      );
      expect(timeline.hourly.length, 6);
      expect(timeline.periods.length, lessThan(timeline.hourly.length));
      expect(timeline.periods.first.grams, isA<BlanketGrams>());
    });

    test('ne fusionne pas une même reco d\'un jour sur l\'autre', () {
      final weather = List.generate(6, (i) {
        return _w(
          timestamp: DateTime(2026, 1, 15, 22).add(Duration(hours: i)),
          temp: 8,
          wind: 10,
        );
      });
      final timeline = engine.calculate(
        horse: _horse(),
        environment: const EnvironmentContext(),
        weather: weather,
        generatedAt: DateTime(2026, 1, 15, 22),
      );
      expect(timeline.periods.length, 2);
      expect(timeline.periods.first.end.day, 16);
      expect(timeline.periods.last.start.day, 16);
    });

    test('prochaine évolution ignore un simple changement de jour', () {
      final weather = [
        _w(timestamp: DateTime(2026, 1, 15, 22), temp: 8),
        _w(timestamp: DateTime(2026, 1, 15, 23), temp: 8),
        _w(timestamp: DateTime(2026, 1, 16, 0), temp: 8),
        _w(timestamp: DateTime(2026, 1, 16, 1), temp: 8),
        _w(timestamp: DateTime(2026, 1, 16, 6), temp: -2),
        _w(timestamp: DateTime(2026, 1, 16, 7), temp: -2),
      ];
      final timeline = engine.calculate(
        horse: _horse(),
        environment: const EnvironmentContext(),
        weather: weather,
        generatedAt: DateTime(2026, 1, 15, 22),
      );
      final current = timeline.periods.first;
      final next = timeline.nextAfter(current);
      expect(timeline.periods.length, greaterThanOrEqualTo(2));
      expect(next, isNotNull);
      expect(next!.grams, isNot(current.grams));
      expect(next.start.hour, 6);
    });

    test('pas de 100 g n\'utilise pas les demi-paliers', () {
      final timeline = engine.calculate(
        horse: _horse(),
        environment: const EnvironmentContext(),
        weather: [_w(timestamp: base, temp: 8)],
        generatedAt: base,
        gramStep: 100,
      );
      expect(timeline.periods.first.grams.value % 100, 0);
    });

    test('offset personnel à 22 °C → pas de garnissage', () {
      final timeline = engine.calculate(
        horse: _horse(offset: 400),
        environment: const EnvironmentContext(),
        weather: [_w(timestamp: DateTime(2026, 7, 15, 14), temp: 22)],
        generatedAt: DateTime(2026, 7, 15, 14),
      );
      expect(timeline.periods.first.grams.hasFill, isFalse);
      expect(timeline.periods.first.grams, BlanketGrams.none);
    });

    test('offset personnel augmente le grammage', () {
      final baseRec = engine.calculate(
        horse: _horse(offset: 0),
        environment: const EnvironmentContext(),
        weather: [_w(timestamp: base, temp: 7)],
        generatedAt: base,
      );
      final adjusted = engine.calculate(
        horse: _horse(offset: 100),
        environment: const EnvironmentContext(),
        weather: [_w(timestamp: base, temp: 7)],
        generatedAt: base,
      );
      expect(
        adjusted.periods.first.grams.value,
        greaterThanOrEqualTo(baseRec.periods.first.grams.value),
      );
    });

    test('explicabilité présente un résumé', () {
      final timeline = engine.calculate(
        horse: _horse(clipping: ClippingLevel.light),
        environment: const EnvironmentContext(),
        weather: [
          _w(
            timestamp: base,
            temp: 5,
            wind: 25,
            precip: 1,
            condition: WeatherCondition.rain,
          ),
        ],
        generatedAt: base,
      );
      final reason = timeline.periods.first.reason;
      expect(reason.summary, contains('g'));
      expect(reason.confidence, isNotNull);
    });
  });
}
