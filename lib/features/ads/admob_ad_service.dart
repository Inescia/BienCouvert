import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ad_config.dart';
import 'ad_gate.dart';
import 'ad_service.dart';

/// Interstitiels AdMob, consentement UMP, même rythme que le cahier des charges.
class AdMobAdService implements AdService {
  AdMobAdService({Random? random}) : _random = random ?? Random();

  final Random _random;
  final _warmUp = Completer<void>();
  var _warmUpStarted = false;
  var _sdkReady = false;
  var _loading = false;
  InterstitialAd? _interstitial;

  @override
  Future<void> warmUp() {
    if (!_warmUpStarted) {
      _warmUpStarted = true;
      unawaited(_warmUpInternal());
    }
    return _warmUp.future;
  }

  Future<void> _warmUpInternal() async {
    try {
      await _gatherConsent();
      final canRequest = await ConsentInformation.instance.canRequestAds();
      if (!canRequest) return;
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(maxAdContentRating: MaxAdContentRating.pg),
      );
      await MobileAds.instance.initialize();
      _sdkReady = true;
      _preload();
    } catch (error, stack) {
      debugPrint('AdMob warm-up: $error\n$stack');
    } finally {
      if (!_warmUp.isCompleted) _warmUp.complete();
    }
  }

  Future<void> _gatherConsent() async {
    final done = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        await ConsentForm.loadAndShowConsentFormIfRequired((_) {});
        if (!done.isCompleted) done.complete();
      },
      (error) {
        debugPrint('AdMob consent: ${error.message}');
        if (!done.isCompleted) done.complete();
      },
    );
    await done.future.timeout(const Duration(seconds: 12), onTimeout: () {});
  }

  void _preload() {
    if (_loading || _interstitial != null || !_sdkReady) return;
    _loading = true;
    InterstitialAd.load(
      adUnitId: AdConfig.interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loading = false;
          _interstitial = ad;
        },
        onAdFailedToLoad: (error) {
          _loading = false;
          _interstitial = null;
          debugPrint('AdMob load: $error');
        },
      ),
    );
  }

  @override
  Future<void> maybeShowInterstitial(
    BuildContext context, {
    AdPlacement placement = AdPlacement.feedback,
  }) async {
    await warmUp();
    if (!_sdkReady || !context.mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(AdGate.prefsKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (!AdGate.shouldAttempt(
      nowMs: now,
      lastMs: last,
      roll: _random.nextInt(100),
      placement: placement,
    )) {
      return;
    }

    final ad = _interstitial;
    if (ad == null) {
      _preload();
      return;
    }

    _interstitial = null;
    final dismissed = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        unawaited(prefs.setInt(AdGate.prefsKey, now));
      },
      onAdDismissedFullScreenContent: (shown) {
        shown.dispose();
        _preload();
        if (!dismissed.isCompleted) dismissed.complete();
      },
      onAdFailedToShowFullScreenContent: (shown, error) {
        debugPrint('AdMob show: $error');
        shown.dispose();
        _preload();
        if (!dismissed.isCompleted) dismissed.complete();
      },
    );
    await ad.show();
    await dismissed.future.timeout(
      const Duration(seconds: 90),
      onTimeout: () {},
    );
  }

  @override
  Future<bool> isPrivacyOptionsRequired() async {
    await warmUp();
    try {
      final status = await ConsentInformation.instance
          .getPrivacyOptionsRequirementStatus();
      return status == PrivacyOptionsRequirementStatus.required;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> showPrivacyOptions() async {
    await ConsentForm.showPrivacyOptionsForm((error) {
      if (error != null) debugPrint('AdMob privacy options: ${error.message}');
    });
  }
}
