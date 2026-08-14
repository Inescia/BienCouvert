import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../home/presentation/providers.dart';

class HorsesScreen extends ConsumerWidget {
  const HorsesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final horsesAsync = ref.watch(horsesProvider);
    final selected = ref.watch(selectedHorseProvider);

    return Scaffold(
      appBar: appPageBar(
        title: const Text('Mes chevaux'),
        actions: [
          IconButton(
            onPressed: () => context.push('/horses/new'),
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Ajouter',
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: AppBackdrop(
        child: horsesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.pine),
          ),
          error: (e, _) => Padding(
            padding: AppPagePadding.of(context, behindAppBar: true),
            child: AppSurface(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Impossible de charger tes chevaux.'),
                  const SizedBox(height: AppSpacing.md),
                  SecondaryButton(
                    label: 'Réessayer',
                    onPressed: () =>
                        ref.read(horsesProvider.notifier).refresh(),
                  ),
                ],
              ),
            ),
          ),
          data: (horses) {
            if (horses.isEmpty) {
              return Padding(
                padding: AppPagePadding.of(context, behindAppBar: true),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const BrandMark(size: 100),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Ton écurie est vide',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Ajoute un cheval pour commencer.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    PrimaryButton(
                      label: 'Ajouter un cheval',
                      onPressed: () => context.push('/horses/new'),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: AppPagePadding.of(context, behindAppBar: true),
              itemCount: horses.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final horse = horses[index];
                final isSelected = selected?.id == horse.id;
                return Material(
                  color: isSelected ? AppColors.sageSoft : AppColors.ivory,
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(AppSpacing.md),
                    leading: HorseAvatar(
                      name: horse.name,
                      selected: isSelected,
                    ),
                    title: Text(horse.name),
                    subtitle: Text(
                      isSelected
                          ? '${horse.location.displayName} · sélectionné'
                          : '${horse.location.displayName} · ${horse.housingType.labelFr}',
                    ),
                    trailing: IconButton(
                      tooltip: 'Modifier le profil',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => context.push('/horses/${horse.id}'),
                    ),
                    onTap: () async {
                      await ref
                          .read(settingsProvider.notifier)
                          .selectHorse(horse.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${horse.name} est sélectionné'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                        context.pop();
                      }
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
