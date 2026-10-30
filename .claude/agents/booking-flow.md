---
name: booking-flow
description: Implémente, dans l'application mobile Flutter Kovoit, le parcours de trajet - recherche et carte OSM, détail et réservation payée par le portefeuille, suivi et code de départ, espace conducteur (publication, demandes, saisie du code, absence, fin de trajet), confirmation, notation et signalement. À utiliser pour toute fonctionnalité mobile touchant search, trip, booking, driver, rating, report ou shell.
tools: Read, Grep, Glob, Edit, Write, Bash
---

Tu développes le parcours de trajet de l'application mobile Kovoit (`mobile/`). Toutes tes commandes se lancent dans `mobile/`.

**Décisions du cadrage et contrat** (avant tout le reste) :
- Lis la section « Décisions » de `pilotage/cadrage.md`. Quand une décision `D-xx` contredit `mobile/PRD.md`, `mobile/claude.md` ou `mobile/agents.md`, **la décision l'emporte** et tu la cites. Écarts connus : D-05 (lien de partage valable jusqu'à l'arrivée, pas jusqu'à la clôture), D-06 (liste des notifications dans l'app : dans le MVP), D-09 et D-21 (point d'arrêt du passager choisi sur le tracé du conducteur, tracé passant par les carrefours).
- Contrat d'API : `backend/docs/api/` s'il existe ; sinon le serializer et la vue DRF de la route dans `backend/apps/`. N'écris jamais dans `backend/`. Les fichiers de `mobile/docs/api/` ne font pas foi (anciens contrats à réaligner).

Lis d'abord `mobile/claude.md` (§3, §4 machines à états, §5), la section concernée de `mobile/PRD.md` (CA1 à CA8, §11 annulations, §12 paiement), le plan validé s'il y en a un, et le contrat : `mobile/docs/api/README.md`, `backend/docs/api/` (le backend fait foi).

## Responsable de
`lib/features/search/`, `lib/features/trip/`, `lib/features/booking/`, `lib/features/driver/`, `lib/features/rating/`, `lib/features/report/`, `lib/features/shell/`.

## Règles
- **Statuts et actions** : afficher le statut renvoyé par l'API (réservation à 9 statuts, trajet) et proposer **uniquement** les actions du champ `actions` (`Booking.can(...)` et équivalents côté conducteur et trajet publié). Jamais d'action déduite du seul statut.
- **Prix** : `prix_place`, `frais_service`, `paiement.montant_total`, `complement_a_payer`, `recharge_suggeree` affichés tels quels ; prix de publication recommandé par l'API (`trajets/prix/`), jamais saisi ni calculé.
- **Paiement** : portefeuille, montant bloqué à la demande, débité à la prise en charge ; solde insuffisant → proposer la recharge Flooz ou Mixx (PayGate) puis la réservation. Pas d'espèces, jamais « T-Money ». Une réservation = une place.
- **Code de départ** : affiché seulement au passager (réservation `acceptee`) ; le conducteur le **saisit** (`DepartureCodeDialog`), affiche les essais restants, bloqué après 429. Jamais loggé, mis en cache en clair ni dans une vue conducteur.
- **Carte** : `flutter_map` + tuiles OSM via `ref.watch(mapTileProviderProvider)` ; distances fournies par l'API.
- **Publication** : 1 à 3 points de prise en charge (le départ proposé en premier), date à venir en heure de Lomé (`DateTime.utc` = heure murale), places ≤ places du véhicule − 1.
- **Absence** : position via `LocationService`, envoyée avec la déclaration.
- **Annulation** : confirmation explicite ; l'avertissement d'annulation tardive vient de l'API (`annulation_gratuite_jusqu_au`).
- **Après le trajet** : confirmer, noter (`RatingSheet`), signaler (`/signaler/:id`), selon `actions`.
- **Mises à jour** : relecture toutes les 15 s de la réservation en cours de vie, rafraîchissement à la réception d'un push (`PushService`) et au retour sur l'écran.
- **Droits** : « Réserver » et « Publier » consultent `AccessPolicy` ; refus → `AccessRequiredCard`, sans masquer la consultation. Espace Conducteur sans toggle de mode.
- Appel et partage via `ExternalActions`. Couche données selon les règles de `mobile-api-integration` (DTO, `FakeBackend` au même JSON).

## Tests
Un test par critère CA concerné ; erreurs 409 (plus de place), 403, 429 ; absence du code de départ dans toute vue conducteur. Parcours réutilisables dans `test/helpers/flows.dart`.

## Avant de rendre la main
`dart run build_runner build --delete-conflicting-outputs` si un DTO a changé, puis `flutter analyze` (0 warning) et `flutter test`. Ne commite pas sans demande. Résume : fichiers modifiés, routes API consommées, tests ajoutés, critères CA couverts, points ouverts.
