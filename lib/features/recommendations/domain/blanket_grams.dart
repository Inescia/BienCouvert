/// Grammages de couverture recommandés.
///
/// [none] = rien du tout.
/// [sheet] = imper 0 g (chemise imperméable, sans garnissage thermique).
enum BlanketGrams {
  none(0),
  sheet(0),
  g50(50),
  g100(100),
  g150(150),
  g200(200),
  g250(250),
  g300(300),
  g350(350),
  g400(400);

  const BlanketGrams(this.value);
  final int value;

  bool get isNone => this == none;
  bool get isSheet => this == sheet;
  bool get hasFill => value > 0;

  static BlanketGrams fromValue(int grams, {int step = 50}) {
    if (grams <= 0) return none;
    final resolvedStep = step == 100 ? 100 : 50;
    final clamped = grams.clamp(0, 400);
    final stepped =
        ((clamped + resolvedStep ~/ 2) ~/ resolvedStep) * resolvedStep;
    if (stepped <= 0) return none;
    return BlanketGrams.values.firstWhere(
      (g) => g.value == stepped && g.hasFill,
      orElse: () => BlanketGrams.none,
    );
  }

  static BlanketGrams fromJson(Object? raw) {
    if (raw is String) {
      if (raw == 'g0') return none;
      for (final value in values) {
        if (value.name == raw) return value;
      }
      return none;
    }
    if (raw is int) return fromValue(raw);
    return none;
  }

  Object toJson() => name;

  BlanketGrams applyStep(int step) {
    if (!hasFill) return this;
    return fromValue(value, step: step);
  }

  static Iterable<BlanketGrams> valuesForStep(int step) {
    final resolvedStep = step == 100 ? 100 : 50;
    return [
      none,
      sheet,
      ...values.where((g) => g.hasFill && g.value % resolvedStep == 0),
    ];
  }

  String get label => switch (this) {
    none => 'Pas de couverture',
    sheet => 'Imper 0 g',
    _ => '$value g',
  };

  String get heroLabel => switch (this) {
    none => 'A Poil',
    sheet => 'Imper',
    _ => '$value g',
  };
}
