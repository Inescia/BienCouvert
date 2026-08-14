import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_widgets.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackdrop(
        child: SafeArea(
          child: Padding(
            padding: AppPagePadding.of(context),
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(flex: 2),
                    const Center(child: BrandMark(size: 120)),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Bienvenue dans',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: AppColors.muted),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Bien Couvert',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const ElegantDivider(),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'La bonne couverture,\nau bon moment.',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: AppColors.chocolateSoft,
                            height: 1.25,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Découvre quel grammage mettre '
                      'et l\'évolution dans les prochaines heures.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const Spacer(flex: 3),
                    PrimaryButton(
                      label: 'Commencer',
                      onPressed: () => context.go('/onboarding/horse'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Recommandations indicatives - A adapter selon ton observation',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
