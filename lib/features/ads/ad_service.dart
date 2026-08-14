import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ad_config.dart';
import 'ad_gate.dart' show AdPlacement;
import 'admob_ad_service.dart';

export 'ad_gate.dart' show AdPlacement;

/// Abstraction pubs — l’UI n’importe jamais AdMob.
/// Voir `docs/ADS.md`.
abstract class AdService {
  Future<void> warmUp() async {}

  Future<void> maybeShowInterstitial(
    BuildContext context, {
    AdPlacement placement = AdPlacement.feedback,
  });

  Future<bool> isPrivacyOptionsRequired() async => false;

  Future<void> showPrivacyOptions() async {}
}

final adServiceProvider = Provider<AdService>((ref) {
  if (!AdConfig.shouldUseAdMob) return const NoOpAdService();
  return AdMobAdService();
});

final adsPrivacyOptionsRequiredProvider = FutureProvider<bool>((ref) {
  return ref.watch(adServiceProvider).isPrivacyOptionsRequired();
});

/// Desktop, tests, ou release sans ID d’unité AdMob.
class NoOpAdService implements AdService {
  const NoOpAdService();

  @override
  Future<void> warmUp() async {}

  @override
  Future<void> maybeShowInterstitial(
    BuildContext context, {
    AdPlacement placement = AdPlacement.feedback,
  }) async {}

  @override
  Future<bool> isPrivacyOptionsRequired() async => false;

  @override
  Future<void> showPrivacyOptions() async {}
}
