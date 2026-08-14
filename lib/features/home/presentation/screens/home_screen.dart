import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../ads/ad_service.dart';
import '../../../horses/domain/horse.dart';
import '../../../horses/domain/horse_enums.dart';
import '../../../weather/presentation/widgets/weather_now_card.dart';
import '../providers.dart';
import '../widgets/horse_switcher.dart';
import '../widgets/recommendation_hero.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final horse = ref.watch(selectedHorseProvider);
    final horsesAsync = ref.watch(horsesProvider);
    final recommendationAsync = ref.watch(homeRecommendationProvider);

    if (horsesAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (horse == null) {
      return Scaffold(
        body: AppBackdrop(
          child: SafeArea(
            child: Padding(
              padding: AppPagePadding.of(context),
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.centerRight,
                    child: _HomeActions(),
                  ),
                  const Spacer(),
                  const BrandMark(size: 112),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Aucun cheval pour le moment',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Ajoute ton premier poney pour obtenir une recommandation.',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryButton(
                    label: 'Ajouter un cheval',
                    onPressed: () => context.push('/horses/new'),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: AppBackdrop(
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.pine,
            onRefresh: () =>
                ref.read(homeRecommendationProvider.notifier).refresh(),
            child: ListView(
              padding: AppPagePadding.of(context),
              children: [
                Row(
                  children: [
                    Text(
                      greetingForNow(),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 22,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    const _HomeActions(),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                HorseSwitcher(
                  horses: horsesAsync.value ?? const [],
                  selected: horse,
                  onSelected: (h) =>
                      ref.read(settingsProvider.notifier).selectHorse(h.id),
                ),
                if ((ref.watch(settingsProvider).value?.onboardingCompleted ??
                        false) &&
                    !(ref
                            .watch(settingsProvider)
                            .value
                            ?.showDisclaimerAccepted ??
                        false)) ...[
                  const SizedBox(height: AppSpacing.md),
                  _DisclaimerBanner(
                    onAccept: () =>
                        ref.read(settingsProvider.notifier).acceptDisclaimer(),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                recommendationAsync.when(
                  loading: () => const _HomeLoading(),
                  error: (e, _) => _HomeError(
                    message: 'Impossible de charger la recommandation',
                    onRetry: () =>
                        ref.read(homeRecommendationProvider.notifier).refresh(),
                  ),
                  data: (state) => _HomeContent(horse: horse, state: state),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeActions extends StatelessWidget {
  const _HomeActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Mes chevaux',
          onPressed: () => context.push('/horses'),
          icon: Image.asset(
            'assets/icons/horseshoe.png',
            width: 22,
            height: 22,
          ),
          color: AppColors.pine,
          padding: EdgeInsets.zero,
          style: IconButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            minimumSize: const Size(32, 48),
          ),
        ),
        IconButton(
          tooltip: 'Paramètres',
          onPressed: () => context.push('/settings'),
          icon: Image.asset('assets/icons/settings.png', width: 22, height: 22),
          color: AppColors.pine,
          padding: EdgeInsets.zero,
          style: IconButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            minimumSize: const Size(32, 48),
          ),
        ),
      ],
    );
  }
}

class _HomeLoading extends StatelessWidget {
  const _HomeLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 80),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(color: AppColors.copper),
            SizedBox(height: AppSpacing.md),
            Text('On regarde ce qu\'il faut pour ton poney…'),
          ],
        ),
      ),
    );
  }
}

class _HomeError extends StatelessWidget {
  const _HomeError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      child: Column(
        children: [
          const BrandMark(size: 80),
          const SizedBox(height: AppSpacing.md),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          SecondaryButton(label: 'Réessayer', onPressed: onRetry),
        ],
      ),
    );
  }
}

class _HomeContent extends ConsumerWidget {
  const _HomeContent({required this.horse, required this.state});

  final Horse horse;
  final HomeRecommendationState state;

  Future<void> _openTimeline(BuildContext context, WidgetRef ref) async {
    await context.push('/timeline');
    if (!context.mounted) return;
    await ref
        .read(adServiceProvider)
        .maybeShowInterstitial(context, placement: AdPlacement.timeline);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = state.current;
    final weather = state.currentWeather;
    final next = state.next;

    if (current == null || weather == null) {
      return AppSurface(
        child: Column(
          children: [
            const Text('🌦️ Impossible de mettre à jour la météo'),
            if (state.forecast != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Dernières données : ${formatRelativeAge(state.forecast!.fetchedAt)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.errorMessage != null) ...[
          _StaleBanner(
            message: state.errorMessage!,
            fetchedAt: state.forecast?.fetchedAt,
            freshness: state.freshness,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        RecommendationHero(
          horseName: horse.name,
          period: current,
          onTap: () => _openTimeline(context, ref),
        ),
        const SizedBox(height: AppSpacing.lg),
        const SectionTitle('Dehors maintenant'),
        const SizedBox(height: AppSpacing.sm),
        WeatherNowCard(
          weather: weather,
          forecast: state.forecast!,
          location: horse.location.displayName,
          onTap: () => context.push('/weather'),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (next != null) ...[
          const SectionTitle('Prochaine évolution'),
          const SizedBox(height: AppSpacing.sm),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              onTap: () => _openTimeline(context, ref),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEFF4F1), Color(0xFFE4EBE8)],
                  ),
                  border: Border.all(
                    color: AppColors.pine.withValues(alpha: 0.2),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.ivory,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppShadows.soft,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (formatForecastDayLabel(next.start) !=
                                'Aujourd\'hui')
                              Text(
                                formatForecastDayLabel(next.start),
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: AppColors.pine,
                                      fontSize: 9,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            Text(
                              formatHour(next.start),
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(color: AppColors.pine),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'On passe à',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              next.grams.label,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.pine,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ConfidenceRow(confidence: current.reason.confidence),
          const SizedBox(height: AppSpacing.lg),
        ],
        PrimaryButton(
          label: 'Comment était ${horse.name} ?',
          onPressed: () => context.push('/feedback'),
        ),
        const SizedBox(height: AppSpacing.md),
        if (horse.personalAdjustment.feedbackCount > 0) ...[
          AppSurface(
            tint: AppColors.sageSoft.withValues(alpha: 0.55),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.pine, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    horse.personalAdjustment.offsetGrams == 0
                        ? 'Apprentissage en cours · '
                              '${horse.personalAdjustment.feedbackCount} retour'
                              '${horse.personalAdjustment.feedbackCount > 1 ? 's' : ''}'
                        : 'Ajusté pour ${horse.name} · '
                              '${horse.personalAdjustment.offsetGrams > 0 ? '+' : ''}'
                              '${horse.personalAdjustment.offsetGrams} g',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.pine,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StaleBanner extends StatelessWidget {
  const _StaleBanner({
    required this.message,
    required this.freshness,
    this.fetchedAt,
  });

  final String message;
  final WeatherFreshness freshness;
  final DateTime? fetchedAt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.weatherBlueSoft.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Text(
        fetchedAt == null
            ? message
            : '$message\nDernières données : ${formatRelativeAge(fetchedAt!)}',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _ConfidenceRow extends StatelessWidget {
  const _ConfidenceRow({required this.confidence});
  final ConfidenceLevel confidence;

  @override
  Widget build(BuildContext context) {
    final color = switch (confidence) {
      ConfidenceLevel.reliable => AppColors.softSuccess,
      ConfidenceLevel.watch => AppColors.weatherBlue,
      ConfidenceLevel.unusual => AppColors.softError,
    };
    return Row(
      children: [
        Icon(Icons.circle, size: 10, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            confidence.labelFr,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _DisclaimerBanner extends StatelessWidget {
  const _DisclaimerBanner({required this.onAccept});

  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recommandations indicatives',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Les grammages proposés aident à choisir une couverture, '
            'mais ton observation du cheval reste prioritaire.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onAccept,
              child: const Text('J’ai compris'),
            ),
          ),
        ],
      ),
    );
  }
}
