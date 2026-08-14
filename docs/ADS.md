# Publicité — Bien Couvert

L’app reste **gratuite**, financée par des pubs **rares** (interstitiel AdMob). Pas de bandeau, pas de pub à l’ouverture, pas de pub pendant l’onboarding.

## État actuel

| Build | Service | Comportement |
|---|---|---|
| Debug / profile (iOS / Android) | `AdMobAdService` | Unités de **test** Google (`AdMobTestIds`) |
| Release, IDs prod encore en `X` | `NoOpAdService` | Aucune pub |
| Release, IDs prod remplis | `AdMobAdService` | Unités `AdMobProdIds` |
| Desktop / web | `NoOpAdService` | Pas de SDK |

Le choix se fait dans `adServiceProvider`. L’UI appelle seulement `AdService.maybeShowInterstitial`.

## Où ça apparaît

Un seul cooldown **global** : **8 minutes**.

| Placement | Déclencheur | Chance |
|---|---|---|
| `AdPlacement.feedback` | Après un retour « Comment était [cheval] ? » | 35 % |
| `AdPlacement.timeline` | Au **retour** de l’écran Prévisions | 20 % |

Si la pub n’est pas encore chargée, on n’affiche rien (pas d’attente).

## Brancher tes vrais IDs (obligatoire avant le store)

Tout se colle dans `lib/features/ads/ad_config.dart` :

- `AdMobTestIds` : déjà remplis (Google), ne pas y toucher
- `AdMobProdIds` : remplace les `X` par tes IDs console (app `~` et interstitiel `/`)

Les IDs d’**application** prod sont aussi dans :

- Android : `android/app/src/main/AndroidManifest.xml` → `com.google.android.gms.ads.APPLICATION_ID`
- iOS : `ios/Runner/Info.plist` → `GADApplicationIdentifier`

En debug, les **unités** restent celles de test Google (`AdMobTestIds`) : l’ID d’app prod + unités test, c’est le schéma recommandé par Google.

Dans AdMob → Confidentialité et messages : crée un message **RGPD / UMP** pour l’EEE, le Royaume-Uni et la Suisse. Sans ça, le formulaire de consentement ne s’affichera pas (pubs limitées ou absentes en Europe).

Ne pas laisser les IDs de test Google (`ca-app-pub-3940256099942544…`) dans un binaire envoyé aux stores.

## Architecture

```
UI (feedback / accueil)
  → adServiceProvider
      → AdMobAdService     (iOS/Android, si IDs en release)
      → NoOpAdService      (sinon)
```

`AdMobAdService` : consentement UMP au lancement → `MobileAds.initialize()` → précharge un interstitial → `show()` si cooldown + tirage OK.

## Stores et confidentialité

Avant d’envoyer un build **avec** tes IDs :

1. Politique (`docs/PRIVACY.md` + texte in-app) déjà à jour pour AdMob.
2. Play Console : **Oui**, l’app contient des pubs ; déclarer l’identifiant pub si tu l’utilises.
3. App Privacy Apple : pubs / identifiant pub selon le questionnaire ; tracking = selon ATT (l’utilisateur peut refuser).
4. Fiche store : ne pas écrire « Pas de pub ».
5. Âge 4+ : rester en interstitial, pas de programme Enfants / Families.

## Comment tester

```bash
flutter run   # iPhone / Android, pas --release
```

Faire un retour cheval, ou ouvrir puis **revenir** des prévisions. Les pubs de test Google portent souvent un bandeau « Test Ad ».

Si rien ne s’affiche : cooldown 8 min, tirage (35 % / 20 %), pub pas encore préchargée, ou simulateur sans réseau. Relancer l’app ne reset pas le cooldown (`bien_couvert_last_ad_ms` dans SharedPreferences). Pour forcer : désinstaller, ou Paramètres → réinitialiser les données.

## Décisions encore ouvertes

- Rewarded (« +24 h sans pub ») vs interstitial seul.
- Bannière discrète sous la reco.
- Désactiver les pubs après quelques retours utiles.
- Fréquence plus basse en hiver.
