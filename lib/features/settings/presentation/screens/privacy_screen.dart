import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../domain/privacy_policy.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appPageBar(title: const Text(privacyPolicyTitle)),
      extendBodyBehindAppBar: true,
      body: AppBackdrop(
        child: ListView(
          padding: AppPagePadding.of(context, behindAppBar: true),
          children: [
            Text(
              'Dernière mise à jour : $privacyPolicyLastUpdated',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            AppSurface(
              child: Text(
                privacyPolicyBody.trim(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
