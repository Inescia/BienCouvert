# Architecture — Poney au Chaud

## Décisions structurantes

### Stockage local

Persistance **JSON fichiers** via `path_provider`, derrière des interfaces repository.

**Pourquoi pas Isar pour le MVP :** Isar officiel est abandonné ; `isar_community` ajoute une génération de code et des binaires natifs. Les repositories JSON sont local-first, mockables, et interchangeables (Isar / Drift / Firebase plus tard) sans toucher au domaine.

### Météo

Prévisions **Open-Meteo** par défaut (`OpenMeteoWeatherRepository`) : latitude / longitude de l’écurie, sans clé API. Cache JSON local (~30 min). Un toggle « Météo de démonstration » bascule sur `MockWeatherRepository`. Abstraction `WeatherRepository` pour changer de fournisseur.

### State management

Riverpod 3 sans codegen : Notifiers manuels, providers dérivés, injection via providers.

### Moteur de recommandation

Pure Dart dans `features/recommendations/domain/`. Aucune dépendance Flutter / Riverpod / IO.

### Publicité

Abstraction `AdService` (`lib/features/ads/`) : AdMob (interstitiel + UMP) sur iOS/Android, no-op sinon. Détail : [ADS.md](ADS.md).

### Firebase

Non inclus dans le MVP. Les repositories abstraits permettent une sync cloud ultérieure.
