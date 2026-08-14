import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../ads/ad_service.dart';
import '../../../home/presentation/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gramStep = ref.watch(settingsProvider).value?.gramStep ?? 50;

    return Scaffold(
      appBar: appPageBar(title: const Text('Paramètres')),
      extendBodyBehindAppBar: true,
      body: AppBackdrop(
        child: ListView(
          padding: AppPagePadding.of(context, behindAppBar: true),
          children: [
            const Center(child: BrandMark(size: 88)),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Bien Couvert',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              'La bonne couverture, au bon moment.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            const ElegantDivider(),
            const SizedBox(height: AppSpacing.xl),
            AppSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Précision du grammage',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pas de 50 g (plus fin) ou 100 g (plus simple à suivre).',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('50 g'),
                        selected: gramStep == 50,
                        onSelected: (_) =>
                            ref.read(settingsProvider.notifier).setGramStep(50),
                        selectedColor: AppColors.sageSoft,
                      ),
                      ChoiceChip(
                        label: const Text('100 g'),
                        selected: gramStep == 100,
                        onSelected: (_) => ref
                            .read(settingsProvider.notifier)
                            .setGramStep(100),
                        selectedColor: AppColors.sageSoft,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Données',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Supprime les chevaux, les retours et les réglages '
                    'de cet appareil. Tu reprendras l’app comme au '
                    'premier lancement.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: () => _confirmReset(context, ref),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.softError,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('Réinitialiser / supprimer les données'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'À propos des recommandations',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Les grammages proposés sont indicatifs. '
                    'Ils s’appuient sur la météo, le profil de ton cheval '
                    'et tes retours. Ton observation reste toujours prioritaire.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Repères pour un non-tondu, sensibilité normale :',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '• dès 10 °C au sec : pas de couverture\n'
                    '• pluie ou vent vers 10–18 °C : imper 0 g '
                    '(chemise imperméable, sans garnissage)\n'
                    '• vers 5 °C : environ 100 g\n'
                    '• sous 0 °C : environ 200 g\n'
                    'Un cheval tondu est décalé d’environ 5 °C '
                    '(couvert plus tôt / plus chaud). '
                    'Abri, poil et caractère frileux ajustent ensuite.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sources',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'IFCE – Equipedia, « Comment les chevaux s’adaptent-ils au froid ? » '
                    '(Auclair-Ronzaud & Briant, 2025). Zone de confort d’un non-tondu '
                    'en climat tempéré : environ 5 à 25 °C. Pour un tondu, la température '
                    'critique inférieure est plus proche de 5 °C que de −15 °C. '
                    'equipedia.ifce.fr',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Morgan, K. (1998). Thermoneutral zone and critical temperatures of horses. '
                    'Journal of Thermal Biology, 23(1), 59-61. Température critique inférieure : 5 °C.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'University of Kentucky Cooperative Extension, ASC-240 « Blanketing Horses ». '
                    'Zone thermoneutre d’environ 5 à 30 °C ; un cheval tondu doit être couvert '
                    'dès qu’il fait frais, même au box. Une chemise imperméable sans garnissage '
                    '(turnout sheet, 0 g) protège du vent et de la pluie sans beaucoup réchauffer.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Mejdell, C.M. et al. (2019), citée par l’IFCE : à 10 °C par beau temps, '
                    'très peu de chevaux demandent une couverture ; à 5–9 °C sous la pluie, '
                    'presque tous la préfèrent. L’abri reste plus important que la couverture.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Fletcher (2015), citée par l’IFCE : une couverture imperméable au-delà '
                    'd’environ 20 °C peut provoquer une hyperthermie. L’app ne propose donc '
                    'pas d’imper au-dessus de 18 °C.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppSurface(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.sunny),
                title: const Text('Météo réelle'),
                subtitle: const Text(
                  'Les prévisions viennent d’Open-Meteo, selon '
                  'la commune de chaque cheval. Aucune clé API n’est stockée. '
                  'Un cache local évite de relancer la requête trop souvent.',
                ),
              ),
            ),
            if (!kReleaseMode) ...[
              const SizedBox(height: AppSpacing.lg),
              AppSurface(
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.science_outlined),
                  title: const Text('Météo de démonstration'),
                  subtitle: const Text(
                    'Utilise des prévisions fictives au lieu d’Open-Meteo. '
                    'Utile hors ligne ou pour tester l’app.',
                  ),
                  value:
                      ref.watch(settingsProvider).value?.useMockWeather ??
                      false,
                  onChanged: (v) =>
                      ref.read(settingsProvider.notifier).setUseMockWeather(v),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppSurface(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Confidentialité'),
                subtitle: const Text(
                  'Chevaux, retours et réglages restent sur cet appareil. '
                  'Météo : Open-Meteo. Pubs : Google AdMob (occasionnelles).',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings/privacy'),
              ),
            ),
            if (ref.watch(adsPrivacyOptionsRequiredProvider).value == true) ...[
              const SizedBox(height: AppSpacing.lg),
              AppSurface(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.tune_outlined),
                  title: const Text('Options publicitaires'),
                  subtitle: const Text(
                    'Gérer le consentement des pubs (EEE, Royaume-Uni, Suisse).',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => ref.read(adServiceProvider).showPrivacyOptions(),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppSurface(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.gavel_outlined),
                title: const Text('Licences open source'),
                subtitle: const Text(
                  'Polices Outfit et Fraunces (OFL) et bibliothèques.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'Bien Couvert',
                  applicationLegalese:
                      'Les grammages proposés sont indicatifs.',
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final info = snapshot.data;
                final label = info == null
                    ? 'Bien Couvert'
                    : 'Bien Couvert ${info.version} (${info.buildNumber})';
                return Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        'Tout supprimer ?',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      content: const Text(
        'Chevaux, retours et réglages seront effacés de cet appareil. '
        'Cette action est définitive.',
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actionsPadding: const EdgeInsets.all(AppSpacing.md),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: AppColors.softError),
          child: const Text('Tout supprimer'),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  await ref.read(settingsProvider.notifier).resetAllData();
  if (context.mounted) context.go('/welcome');
}
