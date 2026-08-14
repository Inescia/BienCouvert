import 'package:flutter/foundation.dart';

/// IDs de **test** Google. Utilisés en debug / profile.
abstract final class AdMobTestIds {
  static const androidApp = 'ca-app-pub-3940256099942544~3347511713';
  static const iosApp = 'ca-app-pub-3940256099942544~1458002511';
  static const androidInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const iosInterstitial = 'ca-app-pub-3940256099942544/4411468910';
}

/// IDs de **prod** AdMob.
/// `androidApp` / `iosApp` sont aussi dans `AndroidManifest.xml` et `Info.plist`.
abstract final class AdMobProdIds {
  static const androidApp = 'ca-app-pub-6271365377098652~5903658781';
  static const iosApp = 'ca-app-pub-6271365377098652~8768711450';
  static const androidInterstitial = 'ca-app-pub-6271365377098652/3277495441';
  static const iosInterstitial = 'ca-app-pub-6271365377098652/4678207023';
}

abstract final class AdConfig {
  static bool get _isIos => defaultTargetPlatform == TargetPlatform.iOS;

  static bool get platformSupportsAds {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  static bool _isFilled(String id) => id.isNotEmpty && !id.contains('X');

  static bool get hasConfiguredUnitId {
    if (!platformSupportsAds) return false;
    return _isFilled(
      _isIos ? AdMobProdIds.iosInterstitial : AdMobProdIds.androidInterstitial,
    );
  }

  /// Debug : toujours AdMob (unités de test). Release : seulement si prod est remplie.
  static bool get shouldUseAdMob {
    if (!platformSupportsAds) return false;
    if (kReleaseMode) return hasConfiguredUnitId;
    return true;
  }

  static String get interstitialUnitId {
    if (!kReleaseMode) {
      return _isIos
          ? AdMobTestIds.iosInterstitial
          : AdMobTestIds.androidInterstitial;
    }
    return _isIos
        ? AdMobProdIds.iosInterstitial
        : AdMobProdIds.androidInterstitial;
  }
}
