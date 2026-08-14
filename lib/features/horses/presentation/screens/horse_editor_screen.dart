import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../home/presentation/providers.dart';
import '../../domain/horse.dart';
import '../../domain/horse_enums.dart';
import '../../domain/horse_location.dart';
import '../widgets/location_search_field.dart';

class HorseEditorScreen extends ConsumerStatefulWidget {
  const HorseEditorScreen({super.key, required this.horseId});

  final String horseId;

  @override
  ConsumerState<HorseEditorScreen> createState() => _HorseEditorScreenState();
}

class _HorseEditorScreenState extends ConsumerState<HorseEditorScreen> {
  late final TextEditingController _name;
  ClippingLevel _clipping = ClippingLevel.none;
  CoatThickness _coat = CoatThickness.medium;
  HousingType _housing = HousingType.fieldWithShelter;
  double _sensitivity = 0.5;
  bool _saving = false;
  Horse? _existing;
  HorseLocation? _location;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _hydrate());
  }

  void _hydrate() {
    if (widget.horseId.isEmpty) return;
    final horses = ref.read(horsesProvider).value ?? const [];
    try {
      final horse = horses.firstWhere((h) => h.id == widget.horseId);
      setState(() {
        _existing = horse;
        _name.text = horse.name;
        _location = horse.location;
        _clipping = horse.clippingLevel;
        _coat = horse.coatThickness;
        _housing = horse.housingType;
        _sensitivity = horse.coldSensitivity;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return;
    final location = _location;
    if (location == null || !location.hasCoordinates) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choisis un lieu dans la liste pour la météo.'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    final now = DateTime.now();
    final horse = Horse(
      id: _existing?.id ?? widget.horseId,
      name: _name.text.trim(),
      clippingLevel: _clipping,
      coatThickness: _coat,
      coldSensitivity: _sensitivity,
      housingType: _housing,
      shelterAvailable:
          _housing != HousingType.field && _housing != HousingType.paddock,
      location: location,
      personalAdjustment:
          _existing?.personalAdjustment ?? const HorsePersonalAdjustment(),
      createdAt: _existing?.createdAt ?? now,
      updatedAt: now,
    );
    await ref.read(horsesProvider.notifier).save(horse);
    await ref.read(settingsProvider.notifier).selectHorse(horse.id);
    if (mounted) context.pop();
  }

  Future<void> _delete() async {
    if (_existing == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Supprimer ${_existing!.name} ?',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: const Text('Cette action est définitive.'),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actionsPadding: EdgeInsets.all(AppSpacing.md),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(horsesProvider.notifier).delete(_existing!.id);
      if (mounted) context.go('/horses');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = _existing != null;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: appPageBar(
        title: const Text('Profil'),
        actions: [
          if (isEdit)
            IconButton(
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: AppPagePadding.of(context, behindAppBar: true),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nom'),
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            scrollPadding: const EdgeInsets.only(bottom: 120),
          ),
          const SizedBox(height: AppSpacing.md),
          LocationSearchField(
            initial: _location,
            onChanged: (loc) => setState(() => _location = loc),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Tonte', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ClippingLevel.values.map((c) {
              return ChoiceChip(
                label: Text(c.labelFr),
                selected: _clipping == c,
                onSelected: (_) => setState(() => _clipping = c),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Poil', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            children: CoatThickness.values.map((c) {
              return ChoiceChip(
                label: Text(c.labelFr),
                selected: _coat == c,
                onSelected: (_) => setState(() => _coat = c),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Sensibilité · ${coldSensitivityLabel(_sensitivity)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Slider(
            value: _sensitivity,
            onChanged: (v) => setState(() => _sensitivity = v),
            activeColor: AppColors.pine,
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Logement', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: HousingType.values.map((h) {
              return ChoiceChip(
                label: Text(h.labelFr),
                selected: _housing == h,
                onSelected: (_) => setState(() => _housing = h),
              );
            }).toList(),
          ),
          if (isEdit &&
              (_existing!.personalAdjustment.offsetGrams != 0 ||
                  _existing!.personalAdjustment.feedbackCount > 0)) ...[
            const SizedBox(height: AppSpacing.md),
            AppSurface(
              child: Text(
                'Ajustement personnel : '
                '${_existing!.personalAdjustment.offsetGrams >= 0 ? '+' : ''}'
                '${_existing!.personalAdjustment.offsetGrams} g '
                '(${_existing!.personalAdjustment.feedbackCount} retours)',
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: 'Enregistrer',
            isLoading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
