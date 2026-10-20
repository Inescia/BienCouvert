import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../domain/horse_time_window.dart';

/// Section profil : jusqu'à 5 plages horaires + switch notif par plage.
class TimeWindowsSection extends StatelessWidget {
  const TimeWindowsSection({
    super.key,
    required this.windows,
    required this.onChanged,
  });

  final List<HorseTimeWindow> windows;
  final ValueChanged<List<HorseTimeWindow>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Plages horaires', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Définis tes passages (matin, soir, nuit…). '
          'On calcule la couverture pour toute la plage.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (windows.isEmpty)
          AppSurface(
            child: Text(
              'Aucune plage pour l’instant. Ajoutes-en une pour voir '
              'la recommandation sur l’accueil.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ...windows.asMap().entries.map((entry) {
          final index = entry.key;
          final window = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _WindowCard(
              window: window,
              onChanged: (next) {
                final list = [...windows];
                list[index] = next;
                onChanged(list);
              },
              onRemove: () {
                final list = [...windows]..removeAt(index);
                onChanged(list);
              },
            ),
          );
        }),
        if (windows.length < HorseTimeWindow.maxPerHorse)
          OutlinedButton.icon(
            onPressed: () => onChanged([
              ...windows,
              HorseTimeWindow.create(
                startMinutes: windows.isEmpty ? 7 * 60 + 30 : 18 * 60,
                endMinutes: windows.isEmpty ? 9 * 60 : 8 * 60,
              ),
            ]),
            icon: const Icon(Icons.add_rounded),
            label: Text(
              windows.isEmpty
                  ? 'Ajouter une plage'
                  : 'Ajouter une plage (${windows.length}/${HorseTimeWindow.maxPerHorse})',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.pine,
              side: BorderSide(color: AppColors.pine.withValues(alpha: 0.35)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
      ],
    );
  }
}

class _WindowCard extends StatelessWidget {
  const _WindowCard({
    required this.window,
    required this.onChanged,
    required this.onRemove,
  });

  final HorseTimeWindow window;
  final ValueChanged<HorseTimeWindow> onChanged;
  final VoidCallback onRemove;

  Future<void> _pickStart(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: window.startMinutes ~/ 60,
        minute: window.startMinutes % 60,
      ),
      helpText: 'Début de plage',
    );
    if (picked == null) return;
    onChanged(
      window.copyWith(startMinutes: picked.hour * 60 + picked.minute),
    );
  }

  Future<void> _pickEnd(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: window.endMinutes ~/ 60,
        minute: window.endMinutes % 60,
      ),
      helpText: 'Fin de plage',
    );
    if (picked == null) return;
    onChanged(window.copyWith(endMinutes: picked.hour * 60 + picked.minute));
  }

  @override
  Widget build(BuildContext context) {
    final overnight = window.crossesMidnight;
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  overnight ? 'Plage (nuit)' : 'Plage',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Supprimer',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _TimeButton(
                  label: 'Début',
                  value: window.labelRange.split(' → ').first,
                  onTap: () => _pickStart(context),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward_rounded, size: 18),
              ),
              Expanded(
                child: _TimeButton(
                  label: 'Fin',
                  value: window.labelRange.split(' → ').last,
                  onTap: () => _pickEnd(context),
                ),
              ),
            ],
          ),
          if (overnight) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Traverse minuit · ${window.duration.inHours} h'
              '${window.duration.inMinutes % 60 == 0 ? '' : ' ${window.duration.inMinutes % 60} min'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Notification',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Text(
              'Rappel à ${window.labelRange.split(' → ').first} '
              'avec la couverture recommandée',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            value: window.notificationsEnabled,
            activeTrackColor: AppColors.pine.withValues(alpha: 0.45),
            activeThumbColor: AppColors.pine,
            onChanged: (v) =>
                onChanged(window.copyWith(notificationsEnabled: v)),
          ),
        ],
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.sageSoft.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 2),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}
