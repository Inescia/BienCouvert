import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../ads/ad_gate.dart';
import '../../../core/utils/local_json_store.dart';
import '../../feedback/data/local_feedback_repository.dart';
import '../../feedback/domain/blanket_feedback.dart';
import '../../feedback/domain/feedback_repository.dart';
import '../../feedback/domain/personalization_service.dart';
import '../../horses/data/local_horse_repository.dart';
import '../../horses/domain/horse.dart';
import '../../horses/domain/horse_enums.dart';
import '../../horses/domain/horse_repository.dart';
import '../../recommendations/domain/recommendation.dart';
import '../../recommendations/domain/recommendation_engine.dart';
import '../../settings/data/local_settings_repository.dart';
import '../../settings/domain/app_settings.dart';
import '../../weather/data/local_weather_cache_repository.dart';
import '../../weather/data/mock_weather_repository.dart';
import '../../weather/data/open_meteo_geocoding.dart';
import '../../weather/data/open_meteo_weather_repository.dart';
import '../../weather/domain/hourly_weather.dart';
import '../../weather/domain/weather_repository.dart';

final localJsonStoreProvider = Provider<LocalJsonStore>((ref) {
  return LocalJsonStore();
});

final horseRepositoryProvider = Provider<HorseRepository>((ref) {
  return LocalHorseRepository(ref.watch(localJsonStoreProvider));
});

final feedbackRepositoryProvider = Provider<FeedbackRepository>((ref) {
  return LocalFeedbackRepository(ref.watch(localJsonStoreProvider));
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return LocalSettingsRepository(ref.watch(localJsonStoreProvider));
});

final weatherCacheRepositoryProvider = Provider<WeatherCacheRepository>((ref) {
  return LocalWeatherCacheRepository(ref.watch(localJsonStoreProvider));
});

final weatherRepositoryProvider = Provider<WeatherRepository>((ref) {
  final useMock =
      !kReleaseMode &&
      (ref.watch(settingsProvider).value?.useMockWeather ?? false);
  if (useMock) return MockWeatherRepository();
  return OpenMeteoWeatherRepository();
});

final geocodingProvider = Provider<OpenMeteoGeocoding>((ref) {
  return OpenMeteoGeocoding();
});

final cachedWeatherServiceProvider = Provider<CachedWeatherService>((ref) {
  return CachedWeatherService(
    remote: ref.watch(weatherRepositoryProvider),
    cache: ref.watch(weatherCacheRepositoryProvider),
  );
});

final recommendationEngineProvider = Provider<RecommendationEngine>((ref) {
  return RecommendationEngine();
});

final personalizationServiceProvider = Provider<PersonalizationService>((ref) {
  return const PersonalizationService();
});

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() {
    return ref.watch(settingsRepositoryProvider).get();
  }

  Future<void> saveSettings(AppSettings settings) async {
    await ref.read(settingsRepositoryProvider).save(settings);
    state = AsyncData(settings);
  }

  Future<void> completeOnboarding({bool disclaimerAccepted = false}) async {
    final current = state.value ?? const AppSettings();
    await saveSettings(
      current.copyWith(
        onboardingCompleted: true,
        showDisclaimerAccepted: disclaimerAccepted,
      ),
    );
  }

  Future<void> acceptDisclaimer() async {
    final current = state.value ?? const AppSettings();
    await saveSettings(current.copyWith(showDisclaimerAccepted: true));
  }

  Future<void> setUseMockWeather(bool value) async {
    final current = state.value ?? const AppSettings();
    await saveSettings(current.copyWith(useMockWeather: value));
  }

  Future<void> selectHorse(String? horseId) async {
    final current = state.value ?? const AppSettings();
    await saveSettings(
      current.copyWith(
        selectedHorseId: horseId,
        clearSelectedHorseId: horseId == null,
      ),
    );
  }

  Future<void> setGramStep(int step) async {
    final current = state.value ?? const AppSettings();
    await saveSettings(current.copyWith(gramStep: step));
  }

  /// Efface chevaux, retours, réglages et cache météo, puis revient au départ.
  Future<void> resetAllData() async {
    await ref.read(localJsonStoreProvider).deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AdGate.prefsKey);
    state = const AsyncData(AppSettings());
    await ref.read(horsesProvider.notifier).refresh();
  }
}

final horsesProvider = AsyncNotifierProvider<HorsesNotifier, List<Horse>>(
  HorsesNotifier.new,
);

class HorsesNotifier extends AsyncNotifier<List<Horse>> {
  @override
  Future<List<Horse>> build() {
    return ref.watch(horseRepositoryProvider).getAll();
  }

  Future<void> refresh() async {
    state = AsyncData(await ref.read(horseRepositoryProvider).getAll());
  }

  Future<void> save(Horse horse) async {
    await ref.read(horseRepositoryProvider).save(horse);
    await refresh();
  }

  Future<void> delete(String id) async {
    await ref.read(horseRepositoryProvider).delete(id);
    final settings = ref.read(settingsProvider).value;
    if (settings?.selectedHorseId == id) {
      await ref.read(settingsProvider.notifier).selectHorse(null);
    }
    await refresh();
  }
}

final selectedHorseProvider = Provider<Horse?>((ref) {
  final horses = ref.watch(horsesProvider).value ?? const [];
  if (horses.isEmpty) return null;
  final selectedId = ref.watch(settingsProvider).value?.selectedHorseId;
  if (selectedId != null) {
    for (final h in horses) {
      if (h.id == selectedId) return h;
    }
  }
  return horses.first;
});

class HomeRecommendationState {
  const HomeRecommendationState({
    required this.timeline,
    required this.forecast,
    this.errorMessage,
  });

  final RecommendationTimeline? timeline;
  final HourlyForecast? forecast;
  final String? errorMessage;

  RecommendationPeriod? get current => timeline?.current;

  RecommendationPeriod? get next {
    final c = current;
    if (c == null || timeline == null) return null;
    return timeline!.nextAfter(c);
  }

  HourlyWeather? get currentWeather {
    final forecast = this.forecast;
    if (forecast == null || forecast.hours.isEmpty) return null;
    return forecast.weatherAt(DateTime.now());
  }

  WeatherFreshness get freshness =>
      forecast?.freshness ?? WeatherFreshness.unavailable;
}

final homeRecommendationProvider =
    AsyncNotifierProvider<HomeRecommendationNotifier, HomeRecommendationState>(
      HomeRecommendationNotifier.new,
    );

class HomeRecommendationNotifier
    extends AsyncNotifier<HomeRecommendationState> {
  @override
  Future<HomeRecommendationState> build() async {
    final horse = ref.watch(selectedHorseProvider);
    if (horse == null) {
      return const HomeRecommendationState(timeline: null, forecast: null);
    }
    final gramStep = ref.watch(settingsProvider).value?.gramStep ?? 50;
    final useMock =
        !kReleaseMode &&
        (ref.watch(settingsProvider).value?.useMockWeather ?? false);
    return _load(horse, forceRefresh: useMock, gramStep: gramStep);
  }

  Future<void> refresh() async {
    final horse = ref.read(selectedHorseProvider);
    if (horse == null) return;
    final gramStep = ref.read(settingsProvider).value?.gramStep ?? 50;
    state = const AsyncLoading();
    state = AsyncData(
      await _load(horse, forceRefresh: true, gramStep: gramStep),
    );
  }

  Future<HomeRecommendationState> _load(
    Horse horse, {
    required bool forceRefresh,
    int gramStep = 50,
  }) async {
    if (!horse.location.hasCoordinates) {
      return HomeRecommendationState(
        timeline: null,
        forecast: null,
        errorMessage:
            'Indique la commune de ${horse.name} pour adapter la météo.',
      );
    }

    final weatherService = ref.read(cachedWeatherServiceProvider);
    final engine = ref.read(recommendationEngineProvider);

    final forecast = await weatherService.getForecast(
      horse.location,
      forceRefresh: forceRefresh,
    );

    if (forecast.hours.isEmpty) {
      return HomeRecommendationState(
        timeline: null,
        forecast: forecast,
        errorMessage: 'Impossible de mettre à jour la météo',
      );
    }

    final timeline = engine.calculate(
      horse: HorseProfile.fromHorse(horse),
      environment: const EnvironmentContext(),
      weather: forecast.hours,
      gramStep: gramStep,
    );

    return HomeRecommendationState(
      timeline: timeline,
      forecast: forecast,
      errorMessage: forecast.freshness == WeatherFreshness.unavailable
          ? 'Impossible de mettre à jour la météo'
          : forecast.freshness == WeatherFreshness.stale
          ? 'Données météo un peu anciennes'
          : null,
    );
  }
}

final feedbacksForSelectedHorseProvider =
    StreamProvider.autoDispose<List<BlanketFeedback>>((ref) {
      final horse = ref.watch(selectedHorseProvider);
      if (horse == null) return Stream.value(const []);
      return ref.watch(feedbackRepositoryProvider).watchForHorse(horse.id);
    });
