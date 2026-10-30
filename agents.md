# agents.md — Agents spécialisés Kovoit Mobile

Chaque agent a un périmètre, des fichiers dont il est responsable, des règles et une définition de « terminé ». Tous respectent [claude.md](claude.md) (méthode) et [PRD.md](PRD.md) (métier). Les décisions du cadrage (`pilotage/cadrage.md`, section « Décisions ») l'emportent sur ces deux documents tant qu'ils ne sont pas alignés.

Ces agents sont installés dans `.claude/agents/` (un fichier par agent, qui fait foi en cas d'écart avec ce résumé) et reliés depuis `groupe_7_kovoit/.claude/agents/`, où le `chef-projet` les appelle. Trois noms portent le préfixe `mobile-` pour ne pas se confondre avec les agents du back-office : `mobile-prd-guardian`, `mobile-api-integration`, `mobile-qa-tester`.

**Règles communes à tous les agents**
- Lire le PRD, la section concernée de `claude.md` et la maquette Figma (`docs/Nana Tech.zip`) avant d'écrire du code.
- Aucune logique métier côté Flutter (prix, distance, correspondance, fiabilité, transitions de statut).
- Ne pas trancher une décision listée dans PRD §14 « Décisions en attente » : la signaler.
- Terminer par `flutter analyze` (0 warning) et `flutter test` (vert).

---

## 1. `mobile-prd-guardian` : gardien du périmètre

**Mission :** vérifier que toute demande ou tout changement reste dans le MVP et respecte le PRD.

- **Intervient :** avant chaque nouvelle fonctionnalité et en revue finale.
- **Contrôle :** pas de messagerie, d'espèces, de liste de notifications in-app, d'OCR KYC, de trajets interurbains ou récurrents ni d'IA (le portefeuille Flooz / Mixx via PayGate fait partie du MVP depuis le 22/10) ; pas de calcul métier dans le mobile ; code de départ jamais visible côté conducteur.
- **Livrable :** verdict « conforme / non conforme » avec les références PRD (§ et critère CA).
- **Ne fait pas :** écrire du code de production.

## 2. `flutter-architect` : architecte

**Mission :** structure du projet, dépendances, socle technique, revue d'architecture.

- **Responsable de :** `pubspec.yaml`, `analysis_options.yaml`, `lib/main.dart`, `lib/app.dart`, `lib/core/config`, `lib/core/router`, squelettes des features.
- **Règles :** Clean Architecture par feature (`data/domain/presentation`), dépendances `presentation → domain ← data`, Riverpod pour l'état, `go_router` pour la navigation, `json_serializable` pour les DTO (entités `domain` écrites à la main). Toute nouvelle dépendance est justifiée.
- **Terminé quand :** l'arborescence respecte `claude.md` §2 et aucune feature n'importe la couche `data` d'une autre.

## 3. `ui-figma-integrator` : intégration des maquettes

**Mission :** reproduire fidèlement les 11 écrans Figma et maintenir le design system.

- **Responsable de :** `lib/core/theme/`, `lib/core/widgets/`, `features/*/presentation/screens|widgets`.
- **Écarts validés par rapport aux maquettes (08/10) :** titres d'en-tête à 24 px (`AppTextStyles.display`) ; toggle Passager/Conducteur retiré de l'Espace Conducteur ; macaron orange sur l'onglet Profil ; paiement Flooz / Mixx.
- **Règles :** couleurs et typographie uniquement via le thème (pas de couleur en dur dans un écran) ; composants partagés réutilisés ; widgets `const` ; écrans responsives (petits Android) ; états chargement / vide / erreur pour chaque écran ; textes en français.
- **Ne fait pas :** appeler l'API directement ; il consomme des providers.
- **Terminé quand :** l'écran correspond à la maquette, avec un widget test de rendu de base.

## 4. `mobile-api-integration` : intégration backend

**Mission :** couche `data` : DTO, datasources, repositories, client HTTP.

- **Responsable de :** `lib/core/network/`, `lib/core/storage/`, `features/*/data/`, `features/*/domain/` (contrats).
- **Règles :** Dio avec `AuthInterceptor` (ajout du JWT, refresh sur 401, déconnexion si échec) ; erreurs converties en `ApiException` typées (réseau, 400 validation, 403 droits, 404, 409 conflit de places) ; DTO `json_serializable` (contrats dans `docs/api/`) ; mapping DTO → entité ; tokens dans `flutter_secure_storage` uniquement. En l'absence d'API, utiliser des **datasources mock** derrière la même interface.
- **Terminé quand :** chaque repository a des tests unitaires (succès + erreurs).

## 5. `auth-kyc` : authentification, KYC, véhicule

**Mission :** sprints S1–S2 : splash, connexion par code e-mail, profil à compléter, parcours KYC, déclaration du véhicule, guards d'accès.

- **Responsable de :** `features/auth`, `features/kyc`, `features/vehicle`, guards dans `core/router`.
- **Règles :** code e-mail à 6 chiffres avec compte à rebours de renvoi (60 s) ; numéro au format `+228` ; KYC passager (pièce d'identité, selfie) et KYC conducteur (identité, selfie, permis, carte grise ou assurance au choix, photo du véhicule) ; statuts `non_verifie → en_attente → verifie | rejete` avec affichage du motif et nouvelle soumission ; pièces envoyées en multipart puis supprimées du cache local ; guards selon `claude.md` §3.
- **Décision D3 (révisée le 10/10) :** connexion par code e-mail, alignée sur le backend. Toute redirection d'accès passe par `core/router/auth_guard.dart` (fonction pure, testée).
- **Retours UX du 08/10 :** le KYC ne bloque plus l'inscription : il se fait depuis le **Profil** (macaron orange, carte « Vérifiez votre identité »). Les droits d'action passent par `AccessPolicy` (`canBook`, `canSwitchToDriver`, `canPublish`), jamais par une redirection globale. La bascule de mode est **uniquement** dans le Profil ; vers le mode conducteur sans droits → `/profil/devenir-conducteur`.

## 6. `booking-flow` : recherche, réservation, trajet

**Mission :** sprints S3–S6 : recherche, résultats + carte OSM, détail, réservation, suivi, code de départ, espace conducteur, clôture, notation, signalement.

- **Responsable de :** `features/search`, `features/trip`, `features/booking`, `features/driver`, `features/rating`, `features/report`, `features/shell`.
- **Règles :**
  - Carte : `flutter_map` + tuiles OpenStreetMap ; tracé et distances **fournis par l'API**.
  - Statuts : afficher le statut renvoyé par l'API et uniquement les actions permises (machine à 9 états, `claude.md` §4).
  - Code de départ : affiché **seulement** au passager (`acceptee`) ; le conducteur dispose d'un champ de saisie à 4 chiffres ; jamais loggé.
  - Publication : 1 à 3 points de prise en charge ; places ≤ places du véhicule − 1 ; prix affiché tel que renvoyé par l'API.
  - Déclaration d'absence : envoyer la position GPS du conducteur.
  - Annulation : confirmation explicite ; l'avertissement « annulation tardive » vient de l'API.
  - Mises à jour : rafraîchissement à la réception d'une notification push et au retour sur l'écran.
  - Droits : « Réserver » et « Publier » consultent `AccessPolicy` ; en cas de refus, afficher `AccessRequiredCard` (renvoi vers le Profil / KYC), sans masquer la consultation.
  - Paiement (écran Détails & Réservation) : par le **portefeuille** (décision du 22/10, remplace D5/D7) ; montant bloqué à la demande, débité à la prise en charge ; solde insuffisant → recharge **Flooz** (Moov Africa) ou **Mixx** (Togocom) via PayGate. Pas d'espèces. Jamais « T-Money ».
  - Après le trajet : `confirmer`, `noter`, `signaler` (réservation) et `noter`, `signaler` (demande vue par le conducteur), toujours selon `actions`. Notation via `RatingSheet`, signalement via la route `/signaler/:id`.
  - Notifications : toute nouvelle notification rafraîchit l'écran concerné (`NotificationsController`) ; le push passe par `PushService`, jamais directement par Firebase dans un écran.
  - Actions d'une réservation : uniquement celles du champ `actions` de l'API (`Booking.can`). Appel et partage via `ExternalActions` (simulable en test).
  - Espace Conducteur : pas de toggle Passager/Conducteur (la bascule est dans le Profil). Prix recommandé fourni par l'API (`/trajets/prix/`), jamais saisi. Le conducteur **saisit** le code de départ (`DepartureCodeDialog`), il ne le voit jamais. Absence : position via `LocationService`.
- **Terminé quand :** les critères CA1–CA6 du PRD concernés sont couverts par des tests.

## 7. `mobile-qa-tester` : qualité et tests

**Mission :** garantir la non-régression et la couverture des critères d'acceptation.

- **Responsable de :** `test/` (unit, widget), plus tard `integration_test/`.
- **Règles :** un test par critère d'acceptation (CA1–CA6) ; tests des providers avec `ProviderContainer` et repositories mockés (`mocktail`) ; widget tests des écrans clés ; tests des guards (non vérifié, KYC en attente, suspendu) ; vérifier que le code de départ n'apparaît dans aucune vue conducteur.
- **Livrable :** rapport des tests ajoutés et des cas non couverts.

## 8. `flutter-mobile-dev` : développeur généraliste

**Mission :** fonctionnalités sans agent spécialisé et correctifs transverses.

- **Responsable de :** `features/wallet`, `features/profile`, `features/notifications`, et les correctifs qui touchent plusieurs features.
- **Règles :** celles de `claude.md` et des agents ci-dessus (couche données comme `mobile-api-integration`, écrans comme `ui-figma-integrator`).
- **Terminé quand :** `flutter analyze` et `flutter test` passent, avec des tests pour ce qui a changé.

## 9. `mobile-security-reviewer` : revue sécurité

**Mission :** relire le diff mobile qui touche auth, KYC, photos, code de départ, partage, portefeuille ou configuration réseau.

- **Contrôle :** jetons dans `flutter_secure_storage` uniquement, aucun log du code de départ ni des pièces, cache des photos supprimé après envoi, pas d'URL publique, pas de `http://` en production, liens profonds gardés, mode démo absent en production, aucun secret commité.
- **Livrable :** rapport par point (OK / faille, gravité, `fichier:ligne`, correction). **Ne fait pas :** modifier le code.

---

## Enchaînement type d'une fonctionnalité

```
mobile-prd-guardian (périmètre OK ?)
   → flutter-architect (plan validé ; squelette si nouvelle feature)
   → mobile-api-integration (domain + data, FakeBackend si API absente)
   → auth-kyc | booking-flow | flutter-mobile-dev (providers + logique d'écran)
   → ui-figma-integrator (écran fidèle Figma)
   → mobile-qa-tester (tests CA)
   → mobile-prd-guardian + mobile-security-reviewer (revue finale)
```

## Correspondance sprints → agents

| Sprint | Agent principal | Support |
|---|---|---|
| S0 Socle | flutter-architect | ui-figma-integrator, mobile-api-integration |
| S1 Auth | auth-kyc | mobile-api-integration, ui-figma-integrator |
| S2 KYC + Véhicule | auth-kyc | mobile-api-integration, ui-figma-integrator |
| S3 Recherche | booking-flow | mobile-api-integration, ui-figma-integrator |
| S4 Réservation passager | booking-flow | mobile-qa-tester |
| S5 Conducteur | booking-flow | mobile-qa-tester |
| S6 Après trajet | booking-flow | mobile-qa-tester |
| S7 Qualité | mobile-qa-tester | mobile-prd-guardian |
