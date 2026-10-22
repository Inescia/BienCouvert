import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../home/presentation/providers.dart';
import '../../domain/hourly_weather.dart';
import '../widgets/weather_daily_forecast.dart';
import '../widgets/weather_hourly_chart.dart';
import '../widgets/weather_now_card.dart';

class WeatherDetailsScreen extends ConsumerWidget {
  const WeatherDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(homeRecommendationProvider);
    final horse = ref.watch(selectedHorseProvider);
    final location = horse?.location.displayName;

    return Scaffold(
      appBar: appPageBar(title: const Text('Météo')),
      extendBodyBehindAppBar: true,
      body: AppBackdrop(
        child: async.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.pine),
          ),
          error: (e, _) => _MessageState(
            icon: Icons.cloud_off_outlined,
            title: 'Impossible de charger la météo',
            subtitle: '$e',
            action: SecondaryButton(
              label: 'Réessayer',
              onPressed: () =>
                  ref.read(homeRecommendationProvider.notifier).refresh(),
            ),
          ),
          data: (state) {
            final hours = state.forecast?.hours ?? const <HourlyWeather>[];
            if (hours.isEmpty) {
              return const _MessageState(
                icon: Icons.cloud_outlined,
                title: 'Pas de données météo',
                subtitle: 'Tire vers le bas pour actualiser.',
              );
            }

            final current = state.currentWeather;
            final days = groupWeatherByDay(hours);

            return RefreshIndicator(
              color: AppColors.pine,
              onRefresh: () =>
                  ref.read(homeRecommendationProvider.notifier).refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: AppPagePadding.of(context, behindAppBar: true),
                children: [
                  if (current != null) ...[
                    WeatherNowCard(
                      weather: current,
                      location: location,
                      forecast: state.forecast!,
                      dayHigh: days.isNotEmpty ? days.first.maxTemp : null,
                      dayLow: days.isNotEmpty ? days.first.minTemp : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  WeatherHourlyChart(hours: hours, current: current),
                  const SizedBox(height: AppSpacing.lg),
                  WeatherDailyForecast(days: days),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppPagePadding.of(context, behindAppBar: true),
        child: AppSurface(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: AppColors.pine),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (action != null) ...[
                const SizedBox(height: AppSpacing.lg),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
