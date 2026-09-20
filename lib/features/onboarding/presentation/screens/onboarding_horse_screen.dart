import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../horses/domain/horse.dart';
import '../../../horses/domain/horse_enums.dart';
import '../../../horses/domain/horse_location.dart';
import '../../../horses/presentation/widgets/location_search_field.dart';
import '../../../home/presentation/providers.dart';

class OnboardingHorseScreen extends ConsumerStatefulWidget {
  const OnboardingHorseScreen({super.key, this.isAdditional = false});

  /// Ajout d’un cheval après le premier : même formulaire, sans relancer l’onboarding.
  final bool isAdditional;

  @override
  ConsumerState<OnboardingHorseScreen> createState() =>
      _OnboardingHorseScreenState();
}

class _OnboardingHorseScreenState extends ConsumerState<OnboardingHorseScreen> {
  final _pageController = PageController();
  final _nameController = TextEditingController();

  int _page = 0;
  ClippingLevel _clipping = ClippingLevel.none;
  CoatThickness _coat = CoatThickness.medium;
  double _sensitivity = 0.5;
  HousingType _housing = HousingType.fieldWithShelter;
  HorseLocation? _location;
  bool _disclaimerAccepted = false;
  bool _saving = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_page == 0 && _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dis-nous comment s\'appelle ton cheval 🐴'),
        ),
      );
      return;
    }
    if (_page == 3 && (_location == null || !_location!.hasCoordinates)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choisis un lieu dans la liste pour la météo.'),
        ),
      );
      return;
    }
    if (_page == 3 && !widget.isAdditional && !_disclaimerAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Coche la case pour confirmer que les grammages sont indicatifs.',
          ),
        ),
      );
      return;
    }
    if (_page < 3) {
      FocusScope.of(context).unfocus();
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    await _finish();
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    final now = DateTime.now();
    final horse = Horse(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      clippingLevel: _clipping,
      coatThickness: _coat,
      coldSensitivity: _sensitivity,
      housingType: _housing,
      shelterAvailable:
          _housing == HousingType.fieldWithShelter ||
          _housing == HousingType.closedBox ||
          _housing == HousingType.boxWithOpening,
      location: _location!,
      createdAt: now,
      updatedAt: now,
    );

    await ref.read(horsesProvider.notifier).save(horse);
    await ref.read(settingsProvider.notifier).selectHorse(horse.id);
    if (!widget.isAdditional) {
      await ref
          .read(settingsProvider.notifier)
          .completeOnboarding(disclaimerAccepted: _disclaimerAccepted);
    }
    if (!mounted) return;
    // Accueil direct (recommandation du cheval fraîchement sélectionné).
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final bottomInset = keyboardOpen
        ? AppSpacing.sm
        : AppSpacing.lg + MediaQuery.viewPaddingOf(context).bottom;
    final headerPad = keyboardOpen
        ? const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.xs,
            AppSpacing.sm,
            AppSpacing.xs,
          )
        : const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
          );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: AppBackdrop(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: headerPad,
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: List.generate(4, (i) {
                          final active = i <= _page;
                          return Expanded(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              height: keyboardOpen ? 3 : 4,
                              decoration: BoxDecoration(
                                color: active
                                    ? AppColors.pine
                                    : AppColors.divider,
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    if (widget.isAdditional)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Annuler',
                      ),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _page = i),
                  children: [
                    _NameStep(
                      controller: _nameController,
                      compact: keyboardOpen,
                    ),
                    _ClippingStep(
                      clipping: _clipping,
                      onClippingChanged: (v) => setState(() => _clipping = v),
                      coat: _coat,
                      onCoatChanged: (v) => setState(() => _coat = v),
                    ),
                    _SensitivityStep(
                      value: _sensitivity,
                      onChanged: (v) => setState(() => _sensitivity = v),
                    ),
                    _HousingLocationStep(
                      housing: _housing,
                      onHousingChanged: (v) => setState(() => _housing = v),
                      location: _location,
                      onLocationChanged: (v) => setState(() => _location = v),
                      disclaimerAccepted: _disclaimerAccepted,
                      onDisclaimerChanged: (v) =>
                          setState(() => _disclaimerAccepted = v),
                      showDisclaimer: !widget.isAdditional,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  keyboardOpen ? AppSpacing.xs : AppSpacing.sm,
                  AppSpacing.lg,
                  bottomInset,
                ),
                child: PrimaryButton(
                  label: _page == 3 ? 'Voir la recommandation' : 'Continuer',
                  isLoading: _saving,
                  onPressed: _next,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NameStep extends StatelessWidget {
  const _NameStep({required this.controller, this.compact = false});
  final TextEditingController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final titleStyle = compact
        ? Theme.of(context).textTheme.headlineMedium
        : Theme.of(context).textTheme.headlineLarge;

    return AppKeyboardScroll(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        compact ? AppSpacing.sm : AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!compact) ...[
            const SizedBox(height: AppSpacing.md),
            const BrandMark(size: 72),
            const SizedBox(height: AppSpacing.lg),
          ],
          Text(
            compact
                ? 'Comment s\'appelle ton cheval ?'
                : 'Comment s\'appelle\nton cheval ?',
            style: titleStyle,
          ),
          SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
          TextField(
            controller: controller,
            textCapitalization: TextCapitalization.words,
            autofocus: true,
            textInputAction: TextInputAction.done,
            scrollPadding: const EdgeInsets.only(bottom: 120),
            decoration: const InputDecoration(
              hintText: 'Nala, Tornado, Pepito…',
            ),
          ),
        ],
      ),
    );
  }
}

class _ClippingStep extends StatelessWidget {
  const _ClippingStep({
    required this.clipping,
    required this.onClippingChanged,
    required this.coat,
    required this.onCoatChanged,
  });

  final ClippingLevel clipping;
  final ValueChanged<ClippingLevel> onClippingChanged;
  final CoatThickness coat;
  final ValueChanged<CoatThickness> onCoatChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppPagePadding.standard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Est-il tondu ?',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Un cheval tondu a généralement besoin de plus de couverture.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: ListView(
              children: [
                ...ClippingLevel.values.map((level) {
                  final selected = level == clipping;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Material(
                      color: selected ? AppColors.sageSoft : AppColors.ivory,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        onTap: () => onClippingChanged(level),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(
                            children: [
                              Icon(
                                selected
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                color: selected
                                    ? AppColors.sageDeep
                                    : AppColors.muted,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Text(
                                level.labelFr,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Et son poil ?',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Un poil épais isole déjà un peu plus.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: CoatThickness.values.map((c) {
                    final selected = c == coat;
                    return ChoiceChip(
                      label: Text(c.labelFr),
                      selected: selected,
                      onSelected: (_) => onCoatChanged(c),
                      selectedColor: AppColors.sageSoft,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SensitivityStep extends StatelessWidget {
  const _SensitivityStep({required this.value, required this.onChanged});
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppKeyboardScroll(
      padding: AppPagePadding.standard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Sensibilité au froid',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tu le connais mieux que quiconque.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Text(
              coldSensitivityLabel(value),
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(color: AppColors.pine),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Slider(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.pine,
            inactiveColor: AppColors.divider,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🥵 Peu frileux',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '🥶 Très frileux',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HousingLocationStep extends StatelessWidget {
  const _HousingLocationStep({
    required this.housing,
    required this.onHousingChanged,
    required this.location,
    required this.onLocationChanged,
    required this.disclaimerAccepted,
    required this.onDisclaimerChanged,
    this.showDisclaimer = true,
  });

  final HousingType housing;
  final ValueChanged<HousingType> onHousingChanged;
  final HorseLocation? location;
  final ValueChanged<HorseLocation?> onLocationChanged;
  final bool disclaimerAccepted;
  final ValueChanged<bool> onDisclaimerChanged;
  final bool showDisclaimer;

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final titleStyle = keyboardOpen
        ? Theme.of(context).textTheme.headlineMedium
        : Theme.of(context).textTheme.headlineLarge;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        keyboardOpen ? AppSpacing.sm : AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          if (!keyboardOpen) const SizedBox(height: AppSpacing.md),
          Text('Où vit ton cheval ?', style: titleStyle),
          if (!keyboardOpen) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'On s’en sert pour la météo réelle de l’écurie.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          SizedBox(height: keyboardOpen ? AppSpacing.sm : AppSpacing.md),
          LocationSearchField(initial: location, onChanged: onLocationChanged),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Type de logement',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          ...HousingType.values.map((h) {
            final selected = h == housing;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Material(
                color: selected ? AppColors.weatherBlueSoft : AppColors.ivory,
                borderRadius: BorderRadius.circular(AppRadii.md),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  onTap: () => onHousingChanged(h),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      h.labelFr,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
              ),
            );
          }),
          if (showDisclaimer) ...[
            const SizedBox(height: AppSpacing.lg),
            AppSurface(
              child: CheckboxListTile(
                value: disclaimerAccepted,
                onChanged: (v) => onDisclaimerChanged(v ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  'Je comprends que les grammages sont indicatifs',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Text(
                  'Ils s’appuient sur la météo et le profil du cheval. '
                  'Ton observation reste toujours prioritaire.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
