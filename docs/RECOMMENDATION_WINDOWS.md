# Recommandations par plage & notifications

> Problème produit : les gens ne changent pas de couverture toutes les heures.
> Certains passent souvent, d’autres une fois par jour. Les horaires sont variables.
> L’app doit conseiller une **plage actionnable** (max 24 h), pas un instantané horaire.
> Les notifications doivent coller à ce conseil, surtout quand ça **change vraiment**.

État actuel (à connaître) :

- Le moteur calcule **heure par heure**, puis regroupe les heures au même grammage
  (`RecommendationPeriod`), coupé à minuit.
- L’accueil montre déjà la période courante + « prochaine évolution ».
- La timeline montre le détail.
- **Aucune notification** n’existe encore dans le code.

Ce document catalogue les idées, puis **choisit une orchestration** pour l’implémentation.

---

## 1. Contraintes utilisateur (non négociables)

| Contrainte | Conséquence produit |
|---|---|
| Horaires de passage variables | Pas de créneau de visite obligatoire à saisir |
| Fréquence très différente (2 h ↔ 24 h+) | Une seule « vérité » : conseil pour une plage, détail en option |
| On ne change pas toutes les heures | Hystérésis / seuil avant de parler de « changement » |
| Max ~1 journée pour un conseil | Plage actionnable ≤ 24 h |
| Notif « mets ça maintenant » inutile | Notifier un **bascule** ou un **point de passage**, pas l’heure courante |

---

## 2. Catalogue d’idées

### 2.1 Comment construire la plage recommandée

| Idée | Principe | Pour | Contre |
|---|---|---|---|
| **A. Collapse actuel** | Fusionner heures au même grammage | Déjà en place, simple | Flicker 50 g / 1 h → trop de « changements » |
| **B. Hystérésis** | N’accepter un nouveau grammage que s’il tient N heures d’affilée (ex. 2–3 h) | Moins de zapping | Peut retarder un vrai froid |
| **C. Durée mini** | Absorber les pics courts dans la plage voisine, marqués « variation » | Plages plus réalistes | Besoin d’afficher la variation |
| **D. Scoring de fenêtre** | Pour [début→fin], prendre le grammage **conservateur** (ex. P80 / max utile) | Idéal « je ne reviens que demain » | Peut sur-couvrir si on passe souvent |
| **E. Grammage modal** | Grammage le plus fréquent dans la fenêtre | Moins agressif | Rate le pic froid de 3 h la nuit |
| **F. Dayparts souples** | Matin / après-midi / soir-nuit comme **ossature**, fusion si même grammage | Langage humain, base notifs | Les dayparts ne sont pas des heures de visite |
| **G. « Jusqu’au prochain vrai changement »** | Depuis maintenant → prochain bascule significatif (≤ 24 h) | CTA clair, sans horaire fixe | Il faut définir « significatif » |
| **H. Double conseil** | « Si tu reviens ce soir » vs « Si tu ne reviens que demain » | Couvre les deux extrêmes | Charge cognitive, UI plus lourde |
| **I. Préférence de rythme** (souvent / 1× jour / 24 h) | L’utilisateur choisit le mode | Personnalisé | L’utilisateur a dit que les horaires sont variables ; réglage facile à mal remplir |
| **J. Apprendre les passages** | Inférer via ouverture app / feedback timestamps | Zéro config | Fragile, privacy, peu de signal au début |

**Verdict idées moteur :** garder A + ajouter B/C + G comme conseil principal. Dayparts (F) comme **langage & notifs**, pas comme contrainte de visite. Pas de I/J en v1.

### 2.2 Comment présenter le conseil (UI)

| Idée | Principe |
|---|---|
| **Hero = plage**, pas « maintenant à l’heure près » | « 200 g · jusqu’à ce soir 18 h » |
| **Bande de variation** | « Dans la plage : 150–200 g » ou « stable » |
| **Fiabilité de plage** | Agrège la confiance des heures + amplitude de variation |
| **Prochain bascule** | Seulement si le delta grammage est ≥ seuil |
| **Timeline inchangée** | Le détail horaire reste pour ceux qui veulent creuser |
| **Carte « Si tu ne reviens que demain matin »** | Conseil conservateur 24 h (idée H, secondaire) |
| **Statut calme** | « Pas de changement important avant demain 8 h » |
| **Libellés daypart** | Ce matin / Cet après-midi / Ce soir / Cette nuit (déjà proches du feedback) |

**Verdict UI :** Hero plage + variation + prochain bascule + timeline détail. Carte « jusqu’à demain » en second temps si utile.

### 2.3 Notifications

| Idée | Principe | Quand envoyer |
|---|---|---|
| **N1. Seuil de bascule** | Notifier seulement si le grammage actionnable change d’au moins 1 cran « utile » (voir §4) | Dès qu’un nouveau bascule entre dans la fenêtre, ou au refresh météo |
| **N2. Points matin / midi / soir** | 3 créneaux de **livraison** locaux (pas des heures de visite) | ~7 h, ~12 h, ~18 h — **uniquement** si le message est nouveau / utile |
| **N3. Digest du jour** | Une seule notif le matin : plan de la journée | Simple, mais rate le bascule de 16 h |
| **N4. Alerte météo rafraîchie** | Si la prévision change fort vs la dernière notif | Rare, important (front froid) |
| **N5. Rappel veille pour la nuit** | Le soir si la nuit demande nettement plus chaud | Très utile pour le passage du soir |
| **N6. Quiet hours** | Pas de notif la nuit profonde | Évident |
| **N7. Par cheval** | Une notif (ou regroupement) multi-chevaux | Nécessaire dès 2+ chevaux |
| **N8. « Confirmer le passage »** | Notif interactive → ouvre feedback | Nice-to-have, plus tard |

**Verdict notifs v1 :** **N2 (matin/midi/soir comme points de passage)** + **filtre N1 (seuil)** + **N5 (soir→nuit)** + **N6**. Le contenu = la **recommandation de plage**, jamais « à cette seconde mets X ».

Pourquoi matin/midi/soir sans imposer l’heure de visite ?

- Ce ne sont pas des RDV à l’écurie.
- Ce sont des **moments où l’app rappelle le plan** pour la prochaine plage, au cas où la personne passe autour.
- Si rien n’a changé depuis la dernière notif → **silence** (évite le spam).
- Si le grammage de la plage à venir diffère → message du type :
  « Ce soir → nuit : passer à 300 g (fiable) » /
  « Matin : rester en 200 g jusqu’à ~17 h ».

---

## 3. Approche retenue : « Plage actionnable + points de bascule »

```text
Météo horaire
    ↓
Score horaire (existant)
    ↓
Collapse intelligent (hystérésis + durée mini + max 24 h)
    ↓
Périodes enrichies (grams, min/max, stabilité, confidence)
    ↓
Conseil actionnable = période qui couvre "maintenant"
                   + prochain bascule significatif
    ↓
UI Accueil / Timeline
    ↓
Scheduler notifs (matin / midi / soir + seuil)
```

### 3.1 Collapse intelligent (moteur)

Sur la liste `HourlyRecommendation` :

1. **Hystérésis** : un nouveau grammage ne démarre une période que s’il tient
   au moins `minStableHours` (défaut **2**). Sinon l’heure est absorbée ;
   on élargit `gramsMin`/`gramsMax` de la période parente.
2. **Durée max** : une période ne dépasse pas **24 h** (même si même grammage).
3. **Coupure calendaire** : on peut **assouplir** la coupure minuit actuelle
   pour la nuit (ex. 18 h → 8 h le lendemain = une plage « soir/nuit »),
   tout en restant ≤ 24 h. Les dayparts restent des labels, pas des murs.
4. **Bascule significative** : `isSignificantChange(a, b)` si
   - passage `none` ↔ couverture remplie, ou
   - `sheet` ↔ remplie, ou
   - écart de grammage ≥ `notificationGramStep` (défaut **100 g**,
     aligné sur `gramStep` utilisateur si 100).

Les micro-variations 50 g ne génèrent ni « prochaine évolution » agressive,
ni notification.

### 3.2 Modèle enrichi

Étendre `RecommendationPeriod` (ou wrapper `ActionablePeriod`) :

| Champ | Rôle |
|---|---|
| `grams` | Conseil principal de la plage |
| `gramsMin` / `gramsMax` | Variation interne (après absorption des pics) |
| `stability` | `stable` \| `variable` (ex. max−min ≥ 100 g → variable) |
| `reason` + `confidence` | Agrégés (pire confiance des heures, ou heure représentative) |
| `daypartLabel` | Matin / Après-midi / Soir / Nuit / Journée… |
| `significantChangeFromPrevious` | bool pour UI + notifs |

`RecommendationTimeline` expose :

- `actionable` : période qui contient maintenant
- `nextSignificantChange` : prochaine période avec bascule significative
- `hourly` : inchangé (détail)

### 3.3 Accueil

- **Hero** : grammage de `actionable` + « jusqu’à {fin / label} »
- Sous-ligne : variation (`stable` ou `150–250 g dans la plage`) + confiance
- **Prochaine évolution** : uniquement `nextSignificantChange` (plus les +50 g)
- Timeline : détail inchangé, éventuellement badge « absorbé / variation »
- CTA feedback : toujours sur la plage (déjà le cas via `FeedbackPeriodOption`)

### 3.4 Notifications (orchestration)

**Pas d’heure de visite.** Trois **points de livraison** locaux par défaut :

| Slot | Heure locale par défaut | Message typique |
|---|---|---|
| Matin | 07:30 | Plan jusqu’au prochain bascule (souvent journée) |
| Midi | 12:30 | Seulement si bascule significative depuis le matin / à venir cet aprem |
| Soir | 18:00 | Plan soir → nuit (souvent le plus important) |

Règles d’envoi (toutes obligatoires) :

1. Les notifs sont **activées** (opt-in OS + toggle app, défaut off jusqu’à permission).
2. Le grammage actionnable (ou le prochain bascule) **diffère** de `lastNotifiedGrams`
   pour ce cheval, **ou** c’est le premier slot du jour avec un plan nuit différent.
3. Le changement est **significatif** (seuil §3.1), sauf digest soir si la nuit
   demande plus chaud que la journée en cours.
4. Quiet hours : pas d’envoi entre 21:30 et 07:00 (hors le slot soir planifié).
5. Multi-chevaux : 1 notif groupée (« Bella 300 g · Apache 200 g ») ou 1 par cheval
   si ≤ 2.

Contenu type :

```text
Titre : Bien Couvert · {cheval}
Corps  : Ce soir → 6 h : 300 g (variation 250–300). Fiable.
Action : Ouvrir l’accueil / la timeline
```

Infra technique (Flutter) :

- `flutter_local_notifications` + timezone / scheduling exact où possible
- Recalcul au refresh météo (~30 min cache déjà là) et au boot / ouverture app
- Persister `lastNotifiedRecommendation` (cheval, grams, periodStart, slot, at)
- Pas de push serveur en v1 (local-first, cohérent avec l’archi)

### 3.5 Ce qu’on ne fait **pas** en v1

- Saisie d’horaires de visite obligatoires
- Apprentissage automatique des passages
- Notif à chaque changement horaire
- Double hero « si tu reviens ce soir / demain » (garde en backlog idée H)
- Firebase / FCM

---

## 4. Plan d’implémentation

### Phase 1 — Domaine (sans UI notifs)

Fichiers principaux :

- [`lib/features/recommendations/domain/recommendation.dart`](../lib/features/recommendations/domain/recommendation.dart)
- [`lib/features/recommendations/domain/recommendation_engine.dart`](../lib/features/recommendations/domain/recommendation_engine.dart)
- [`lib/features/recommendations/domain/recommendation_rules.dart`](../lib/features/recommendations/domain/recommendation_rules.dart)
- Tests : [`test/features/recommendations/`](../test/features/recommendations/)

Travail :

1. Enrichir `RecommendationPeriod` (`gramsMin`/`gramsMax`, `stability`, label daypart).
2. Remplacer `_collapsePeriods` par collapse + hystérésis + max 24 h + nuit continue.
3. Ajouter `isSignificantChange` + `nextSignificantChange` sur le timeline.
4. Agrégation de confiance / raison sur la plage.
5. Tests unitaires : pics d’1 h absorbés, bascule 100 g, plage ≤ 24 h, nuit cross-midnight.

### Phase 2 — UI

Fichiers :

- [`lib/features/home/presentation/widgets/recommendation_hero.dart`](../lib/features/home/presentation/widgets/recommendation_hero.dart)
- [`lib/features/home/presentation/screens/home_screen.dart`](../lib/features/home/presentation/screens/home_screen.dart)
- [`lib/features/recommendations/presentation/screens/timeline_screen.dart`](../lib/features/recommendations/presentation/screens/timeline_screen.dart)
- Feedback : labels daypart déjà proches — aligner sur les nouveaux labels.

Travail :

1. Copy hero : plage + variation + confiance.
2. « Prochaine évolution » filtrée sur bascule significative.
3. Timeline : afficher variation si `variable`.
4. Réglages : toggle « Notifications » (prépare Phase 3) + explication courte.

### Phase 3 — Notifications locales

Nouveau feature module suggéré : `lib/features/notifications/`

- `NotificationScheduler` (domaine pur autant que possible)
- `LocalNotificationService` (Flutter plugin)
- Settings : enabled, heures des 3 slots (avancé, défauts OK)
- Branchement : après `HomeRecommendationNotifier` refresh, et via
  background/boot si supporté simplement (sinon best-effort à l’ouverture)

Tests :

- Règles N1/N2/N5 en tests Dart purs (scheduler)
- Pas de spam si grams inchangé
- Quiet hours

### Phase 4 (backlog)

- Carte secondaire « si tu ne reviens que demain matin »
- Regroupement multi-chevaux soigné
- Ajustement des heures de slot
- Notif interactive → feedback

---

## 5. Critères de succès

- Un utilisateur qui ne passe qu’**une fois le soir** voit un conseil **soir→nuit**
  clair, sans devoir lire 24 lignes horaires.
- Un utilisateur **sur place** peut ouvrir la timeline pour le détail.
- Les notifs ne partent **que** quand le plan de couverture change vraiment
  (ou au point soir pour la nuit si pertinent).
- Zéro demande d’horaire de visite pour que ça marche.
- Plage actionnable **≤ 24 h**.

---

## 6. Décisions figées pour l’implémentation

1. **Pas** de créneaux de visite utilisateur en v1.
2. Conseil principal = **plage actionnable** issue du collapse intelligent.
3. **Matin / midi / soir** = points de **livraison** de notifs + labels, filtrés par **seuil**.
4. Seuil par défaut : **100 g** (ou 1 cran `gramStep` si 100), plus transitions none/sheet/fill.
5. Max plage **24 h** ; hystérésis **2 h** ; nuit peut traverser minuit.
6. Local notifications only ; opt-in.
