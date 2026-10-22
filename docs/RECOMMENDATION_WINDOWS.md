# Plages horaires utilisateur & notifications

## Besoin

Les utilisateurs saisissent leurs **propres plages** (passages à l’écurie),
jusqu’à 5 par cheval. L’app calcule une **couverture pour toute la plage**
(pas seulement l’heure courante) et peut envoyer une **notification au début**
de la plage.

## Profil cheval

Section **Plages horaires** :

- Début / fin (time picker), y compris plages qui **traversent minuit**
- Switch **Notification** par plage
- Max 5 plages

## Accueil

1. **Recommandation par heure** — hero existant (détail horaire / timeline)
2. **Pour tes passages** — une carte par plage saisie : grammage conseillé
   (conservateur = besoin le plus élevé), variation, fiabilité selon les
   écarts de température / de grammage sur la plage

## Agrégation

`WindowRecommendationAggregator` :

- Filtre les `HourlyRecommendation` dans `[start, end)`
- Grammage = max de couverture sur la plage
- `gramsMin` / `gramsMax` pour la variation
- Confiance dégradée si forte amplitude de température (≥ 6 °C → à surveiller,
  ≥ 12 °C → inhabituel) ou de grammage

## Notifications

- Locales (`flutter_local_notifications`), quotidiennes à l’heure de **début**
- Contenu : nom du cheval, plage, recommandation, fiabilité
- Opt-in OS à l’activation du switch
- No-op sur web / desktop non supporté

## Fichiers clés

- `lib/features/horses/domain/horse_time_window.dart`
- `lib/features/recommendations/domain/window_recommendation.dart`
- `lib/features/horses/presentation/widgets/time_windows_section.dart`
- `lib/features/home/presentation/widgets/passage_windows_card.dart`
- `lib/features/notifications/`
