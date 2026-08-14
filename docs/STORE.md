# Publication stores — Bien Couvert

Checklist pour App Store et Google Play. L’app est configurée ; il reste des étapes **à faire sur ton compte** (Apple / Google), qu’aucun code ne peut remplacer.

## Identifiants

| Plateforme | Valeur |
|---|---|
| Nom affiché | Bien Couvert |
| iOS bundle ID | `com.ic.poneyAuChaud` |
| Android applicationId | `com.ic.poney_au_chaud` |
| Version | `1.0.0` (build `1`) dans `pubspec.yaml` |

## Ce qui est déjà prêt dans le projet

- Icône native (plus le logo Flutter)
- Splash / fond d’icône `#C5D7C9` (couleur réelle du logo)
- Polices Outfit / Fraunces **embarquées** (pas de téléchargement au runtime)
- App en français (locale Material / Cupertino)
- HTTPS uniquement, pas de trafic cleartext
- Manifeste de confidentialité iOS (`PrivacyInfo.xcprivacy`)
- `ITSAppUsesNonExemptEncryption = false` (HTTPS standard)
- Portrait uniquement
- Politique de confidentialité dans l’app (Paramètres)
- Licences open source
- Pubs **AdMob** (interstitiel rare) — IDs de test en debug, IDs prod via dart-define — voir [ADS.md](ADS.md)
- Météo réelle Open-Meteo en release

## À faire une fois (comptes)

1. **Politique de confidentialité en ligne**  
   Publie `docs/PRIVACY.md` (GitHub Pages, site perso, Notion public…). Copie l’URL HTTPS dans App Store Connect et Play Console. Sans URL, la fiche est refusée.

2. **Adresse de contact**  
   Ajoute un e-mail support sur les deux consoles, et mets-le aussi dans la politique si tu veux.

3. **Keystore Android (à garder hors Git, pour toujours)**

```bash
keytool -genkey -v \
  -keystore android/app/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

Puis :

```bash
cp android/key.properties.example android/key.properties
```

Remplis les mots de passe. `android/key.properties` et `*.jks` sont déjà dans `.gitignore`.

4. **Captures d’écran** (à prendre sur simulateur / appareil)

- iPhone 6,9" (iPhone 15 Pro Max / 16 Plus) : 1320×2868 ou 2868×1320
- iPhone 6,5" (iPhone 14 Plus / 11 Pro Max) : 1284×2778
- Android téléphone : au moins 2 captures 16:9 ou 9:16
- iPad : seulement si tu coches iPad (aujourd’hui l’app tourne aussi sur iPad en portrait)

Écrans utiles : accueil avec reco, timeline 24 h, fiche météo, paramètres / sources.

## Textes de fiche (à coller)

**Sous-titre (30 car. max, App Store)**  
La bonne couverture, au bon moment.

**Description courte Play (80 car.)**  
Grammage de couverture cheval, selon la météo de l’écurie.

**Description longue**

Bien Couvert t’aide à choisir le grammage de couverture de ton cheval, heure par heure.

Tu indiques le profil (tonte, sensibilité, logement) et la commune de l’écurie. L’app s’appuie sur la météo réelle (Open-Meteo) et te propose un grammage indicatif : rien, imper 0 g, ou 50 à 400 g.

Tu peux dire si c’était trop froid ou trop chaud : l’ajustement reste sur l’appareil, cheval par cheval.

Les recommandations sont indicatives. Ton observation reste prioritaire.

Données locales, sans compte. Seules la latitude et la longitude de l’écurie partent vers Open-Meteo pour la prévision. Des pubs rares (AdMob) aident à garder l’app gratuite.

**Mots-clés App Store (100 car., séparés par des virgules)**  
cheval,couverture,grammage,écurie,poney,météo,tonte,couvert,paddock

**Catégorie**  
Style de vie (Lifestyle). Secondaire : Sports.

**Âge**  
4+ / Tout public. Pas de contenu choquant, pas de chat. Pubs occasionnelles (interstitiel), pas de programme Enfants / Families.

## App Privacy (Apple)

- Suivi (tracking) : **Non** par défaut ; l’utilisateur peut accepter ATT. Si tu déclares du tracking, uniquement après consentement.
- Données utilisées pour le tracking : **Identifiant pub** seulement si l’utilisateur accepte le suivi
- Données collectées par toi : **Aucune** (profils chevaux locaux)
- Données envoyées à un tiers :
  - **Localisation approximative** (commune → lat/lon) vers Open-Meteo, pour la météo, **non liée à l’identité**, **non utilisée pour la pub**
  - **Publicité** via Google AdMob (identifiant pub / données techniques selon consentement UMP)

Si le formulaire demande un type : *Product Interaction / Location — Precise Location* : **non** (pas de GPS). *Coarse Location* : oui, uniquement pour la météo.

## Data safety (Play Console)

- L’app collecte-t-elle des données ? **Oui** (localisation approximative envoyée à Open-Meteo ; pubs Google)
- Localisation approximative : collectée, envoyée hors appareil, **pas vendue**, **pas pour la pub**, finalité : fonctionnalité de l’app
- Publicité : **Oui** (AdMob). Identifiant pub : oui si utilisé par Google selon le consentement
- Chiffrement en transit : **Oui** (HTTPS)
- Les utilisateurs peuvent-ils demander la suppression ? **Oui** (désinstallation / réinitialiser les données dans l’app)
- L’app contient-elle des pubs ? **Oui** (dès qu’un build release part avec tes IDs d’unité). **Non** tant que tu n’as pas mis les dart-define (NoOp)

## Builds de release

```bash
# Android (Play) — AAB
flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info

# iOS (Transporter / Xcode)
flutter build ipa --release --obfuscate --split-debug-info=build/debug-info
```

Le `.aab` se trouve dans `build/app/outputs/bundle/release/`.  
L’`.ipa` dans `build/ios/ipa/`.

Incrémente `version:` dans `pubspec.yaml` à chaque envoi (`1.0.1+2`, etc.).

## Revue Apple / Google — points d’attention

- Compte démo : **non nécessaire** (pas de login).
- Explique dans les notes de revue : « App hors-ligne possible via cache météo ; la commune se cherche via Open-Meteo. Les grammages sont indicatifs (disclaimer à l’onboarding). »
- Ne pas cocher « Health / Medical ».
- Open-Meteo n’a pas besoin de clé : ne pas inventer de secrets dans la fiche.
