class AppFailure implements Exception {
  const AppFailure(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

class WeatherUnavailableFailure extends AppFailure {
  const WeatherUnavailableFailure({
    String message = 'Impossible de mettre à jour la météo',
    super.cause,
  }) : super(message);
}

class NotFoundFailure extends AppFailure {
  const NotFoundFailure(super.message);
}
