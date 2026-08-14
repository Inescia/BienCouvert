import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/feedback/presentation/screens/feedback_screen.dart';
import '../features/home/presentation/providers.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/horses/presentation/screens/horse_editor_screen.dart';
import '../features/horses/presentation/screens/horses_screen.dart';
import '../features/onboarding/presentation/screens/welcome_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_horse_screen.dart';
import '../features/recommendations/presentation/screens/timeline_screen.dart';
import '../features/settings/presentation/screens/privacy_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/weather/presentation/screens/weather_details_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final settings = ref.read(settingsProvider).value;
      final horses = ref.read(horsesProvider).value;
      if (settings == null || horses == null) return null;

      final loc = state.matchedLocation;
      final onboardingDone = settings.onboardingCompleted && horses.isNotEmpty;
      final isOnboarding =
          loc.startsWith('/welcome') || loc.startsWith('/onboarding');

      if (!onboardingDone && !isOnboarding) {
        return horses.isEmpty ? '/welcome' : '/onboarding/horse';
      }
      if (onboardingDone && isOnboarding) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/onboarding/horse',
        builder: (context, state) => const OnboardingHorseScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'timeline',
            builder: (context, state) => const TimelineScreen(),
          ),
          GoRoute(
            path: 'weather',
            builder: (context, state) => const WeatherDetailsScreen(),
          ),
          GoRoute(
            path: 'feedback',
            builder: (context, state) => const FeedbackScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/horses',
        builder: (context, state) => const HorsesScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) =>
                const OnboardingHorseScreen(isAdditional: true),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) =>
                HorseEditorScreen(horseId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'privacy',
            builder: (context, state) => const PrivacyScreen(),
          ),
        ],
      ),
    ],
  );
});

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(this.ref) {
    ref.listen(settingsProvider, (_, _) => notifyListeners());
    ref.listen(horsesProvider, (_, _) => notifyListeners());
  }

  final Ref ref;
}
