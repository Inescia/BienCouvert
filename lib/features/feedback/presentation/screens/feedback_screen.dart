import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../ads/ad_service.dart';
import '../../../horses/domain/horse_enums.dart';
import '../../../recommendations/domain/blanket_grams.dart';
import '../../domain/blanket_feedback.dart';
import '../../domain/feedback_period.dart';
import '../../../home/presentation/providers.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  FeedbackFeeling? _feeling;
  BlanketGrams? _usedGrams;
  PreferredAdjustment? _preferred;
  FeedbackPeriodOption? _period;
  bool _saving = false;
  bool _periodsInitialized = false;

  void _ensurePeriod(List<FeedbackPeriodOption> options) {
    if (_periodsInitialized || options.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _periodsInitialized) return;
      setState(() {
        _periodsInitialized = true;
        _period = options.firstWhere(
          (o) => o.isCurrent,
          orElse: () => options.first,
        );
        _usedGrams = _period?.recommendedGrams;
      });
    });
  }

  Future<void> _submit() async {
    final horse = ref.read(selectedHorseProvider);
    final home = ref.read(homeRecommendationProvider).value;
    if (horse == null || _feeling == null || _period == null) return;

    setState(() => _saving = true);

    final feedback = BlanketFeedback(
      id: const Uuid().v4(),
      horseId: horse.id,
      createdAt: DateTime.now(),
      feeling: _feeling!,
      recommendedGrams: _period!.recommendedGrams,
      usedGrams: _usedGrams,
      preferredAdjustment: _preferred,
      weatherSnapshot: home?.forecast?.weatherAt(_period!.start),
      periodStart: _period!.start,
      periodEnd: _period!.end,
      periodLabel: '${_period!.title} · ${_period!.subtitle}',
    );

    await ref.read(feedbackRepositoryProvider).save(feedback);

    final all = await ref
        .read(feedbackRepositoryProvider)
        .getForHorse(horse.id);
    final adjustment = ref.read(personalizationServiceProvider).compute(all);
    await ref
        .read(horsesProvider.notifier)
        .save(
          horse.copyWith(
            personalAdjustment: adjustment,
            updatedAt: DateTime.now(),
          ),
        );

    if (!mounted) return;
    setState(() => _saving = false);
    final needed = 2;
    final count = adjustment.feedbackCount;
    final message = _feeling == FeedbackFeeling.perfect
        ? '${horse.name} était bien au chaud (${_period!.title.toLowerCase()})'
        : adjustment.offsetGrams != 0
        ? 'Merci — on ajuste de ${adjustment.offsetGrams > 0 ? '+' : ''}${adjustment.offsetGrams} g'
        : count < needed
        ? 'Merci — encore ${needed - count} retour${needed - count > 1 ? 's' : ''} pour personnaliser'
        : 'Merci pour ton retour sur ${_period!.title.toLowerCase()}';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    await ref
        .read(adServiceProvider)
        .maybeShowInterstitial(context, placement: AdPlacement.feedback);
  }

  @override
  Widget build(BuildContext context) {
    final horse = ref.watch(selectedHorseProvider);
    final home = ref.watch(homeRecommendationProvider).value;
    final feedbacks =
        ref.watch(feedbacksForSelectedHorseProvider).value ?? const [];
    final name = horse?.name ?? 'ton cheval';
    final options = buildFeedbackPeriodOptions(timeline: home?.timeline);
    _ensurePeriod(options);
    final selectedExisting = _period == null
        ? null
        : latestFeedbackForPeriod(feedbacks: feedbacks, option: _period!);

    return Scaffold(
      appBar: appPageBar(title: Text('Retour sur $name')),
      extendBodyBehindAppBar: true,
      body: AppBackdrop(
        child: ListView(
          padding: AppPagePadding.of(context, behindAppBar: true),
          children: [
            Text(
              'Pour quelle période ?',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Choisis le moment dont tu parles — maintenant, plus tôt, ou la nuit dernière.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            ...options.map((option) {
              final selected = _period?.id == option.id;
              final existing = latestFeedbackForPeriod(
                feedbacks: feedbacks,
                option: option,
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Material(
                  color: selected
                      ? AppColors.sageSoft
                      : existing != null
                      ? AppColors.sageSoft.withValues(alpha: 0.45)
                      : AppColors.ivory,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    side: existing != null
                        ? BorderSide(
                            color: AppColors.pine.withValues(alpha: 0.28),
                          )
                        : BorderSide.none,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    onTap: () => setState(() {
                      _period = option;
                      if (existing != null) {
                        _feeling = existing.feeling;
                        _usedGrams =
                            existing.usedGrams ?? option.recommendedGrams;
                        _preferred = existing.preferredAdjustment;
                      } else {
                        _usedGrams ??= option.recommendedGrams;
                      }
                    }),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          Icon(
                            selected
                                ? Icons.radio_button_checked
                                : existing != null
                                ? Icons.check_circle
                                : Icons.radio_button_off,
                            color: selected || existing != null
                                ? AppColors.pine
                                : AppColors.muted,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        option.title,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                    ),
                                    if (option.isCurrent) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.copper.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            99,
                                          ),
                                        ),
                                        child: Text(
                                          'En cours',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: AppColors.copperDeep,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  existing == null
                                      ? option.subtitle
                                      : '${existing.feeling.emoji} ${existing.feeling.labelFr}'
                                            ' · ${existing.usedGrams?.label ?? option.recommendedGrams.label}',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: existing != null
                                            ? AppColors.pine
                                            : null,
                                        fontWeight: existing != null
                                            ? FontWeight.w600
                                            : null,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          if (existing != null) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.ivory.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                'Noté',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppColors.pine,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: AppSpacing.lg),
            const ElegantDivider(),
            const SizedBox(height: AppSpacing.lg),
            Text(
              _period == null
                  ? 'Comment était $name ?'
                  : 'Comment était $name ${_period!.isCurrent ? 'maintenant' : '(${_period!.title.toLowerCase()})'} ?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: FeedbackFeeling.values.map((feeling) {
                final selected = _feeling == feeling;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Material(
                      color: selected ? AppColors.sageSoft : AppColors.ivory,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        onTap: () => setState(() {
                          _feeling = feeling;
                          if (feeling == FeedbackFeeling.perfect) {
                            _preferred = null;
                          }
                        }),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          child: Column(
                            children: [
                              Text(
                                feeling.emoji,
                                style: const TextStyle(fontSize: 28),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                feeling.labelFr,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xl),
            const SectionTitle('Tu avais mis combien ?'),
            const SizedBox(height: AppSpacing.sm),
            if (_period != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  'Recommandé sur cette période : ${_period!.recommendedGrams.label}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  BlanketGrams.valuesForStep(
                    ref.watch(settingsProvider).value?.gramStep ?? 50,
                  ).map((g) {
                    final selected = _usedGrams == g;
                    return ChoiceChip(
                      label: Text(g.label),
                      selected: selected,
                      onSelected: (_) => setState(() => _usedGrams = g),
                      selectedColor: AppColors.sageSoft,
                    );
                  }).toList(),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (_feeling != null && _feeling != FeedbackFeeling.perfect) ...[
              const SectionTitle('Tu aurais préféré ?'),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: PreferredAdjustment.values.map((adj) {
                  final selected = _preferred == adj;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: OutlinedButton(
                        onPressed: () => setState(() => _preferred = adj),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: selected ? AppColors.sageSoft : null,
                          side: BorderSide(
                            color: selected
                                ? AppColors.pine
                                : AppColors.divider,
                          ),
                        ),
                        child: Text(
                          adj == PreferredAdjustment.warmer
                              ? 'Plus chaud'
                              : 'Plus léger',
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ] else
              PrimaryButton(
                label: selectedExisting == null ? 'Envoyer' : 'Mettre à jour',
                isLoading: _saving,
                onPressed: _feeling == null || _period == null ? null : _submit,
              ),
          ],
        ),
      ),
    );
  }
}
