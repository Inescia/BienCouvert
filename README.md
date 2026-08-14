# Bien Couvert

> La bonne couverture, au bon moment.

Application mobile Flutter pour propriétaires de chevaux : recommandation de **grammage de couverture**.

*(Ancien nom de projet / package technique : `poney_au_chaud`.)*


## Stack

- Flutter 3.44 / Dart 3.12
- Riverpod 3
- go_router
- Persistance locale JSON (local-first)
- Météo réelle via Open-Meteo (cache local, option démo dans les réglages)

## Lancer

```bash
flutter pub get
flutter run
```

## Tests

```bash
flutter test
flutter analyze
```

## Architecture

Voir [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Publicité

Voir [docs/ADS.md](docs/ADS.md). Interstitiels AdMob rares (après un retour ou au retour des prévisions). En debug : pubs de test Google. En release : tes IDs d’unité via `--dart-define`.

## Publication stores

Voir [docs/STORE.md](docs/STORE.md) (checklist App Store / Play, textes de fiche, confidentialité).
Politique : [docs/PRIVACY.md](docs/PRIVACY.md).

## Parcours MVP

1. Welcome → création du premier cheval
2. Accueil : grammage dominant + prochain changement
3. Timeline 24h (périodes regroupées)
4. Feedback → ajustement personnel progressif
5. Multi-chevaux + paramètres
