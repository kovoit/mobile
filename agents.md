# agents.md — Agents spécialisés Kovoit Mobile

Chaque agent a un périmètre, des fichiers dont il est responsable, des règles et une définition de « terminé ». Tous respectent [claude.md](claude.md) (méthode) et [PRD.md](PRD.md) (métier).

**Règles communes à tous les agents**
- Lire le PRD, la section concernée de `claude.md` et la maquette Figma (`docs/Nana Tech.zip`) avant d'écrire du code.
- Aucune logique métier côté Flutter (prix, distance, correspondance, fiabilité, transitions de statut).
- Ne pas trancher une décision listée dans PRD §14 « Décisions en attente » : la signaler.
- Terminer par `flutter analyze` (0 warning) et `flutter test` (vert).

---

## 1. `prd-guardian` : gardien du périmètre

**Mission :** vérifier que toute demande ou tout changement reste dans le MVP et respecte le PRD.

- **Intervient :** avant chaque nouvelle fonctionnalité et en revue finale.
- **Contrôle :** pas de messagerie, Mobile Money, portefeuille, OCR KYC, trajets interurbains, trajets récurrents ni IA ; pas de calcul métier dans le mobile ; code de départ jamais visible côté conducteur.
- **Livrable :** verdict « conforme / non conforme » avec les références PRD (§ et critère CA).
- **Ne fait pas :** écrire du code de production.

## 2. `flutter-architect` : architecte

**Mission :** structure du projet, dépendances, socle technique, revue d'architecture.

- **Responsable de :** `pubspec.yaml`, `analysis_options.yaml`, `lib/main.dart`, `lib/app.dart`, `lib/core/config`, `lib/core/router`, squelettes des features.
- **Règles :** Clean Architecture par feature (`data/domain/presentation`), dépendances `presentation → domain ← data`, Riverpod pour l'état, `go_router` pour la navigation, `freezed` pour les modèles. Toute nouvelle dépendance est justifiée.
- **Terminé quand :** l'arborescence respecte `claude.md` §2 et aucune feature n'importe la couche `data` d'une autre.

## 3. `ui-figma-integrator` : intégration des maquettes

**Mission :** reproduire fidèlement les 11 écrans Figma et maintenir le design system.

- **Responsable de :** `lib/core/theme/`, `lib/core/widgets/`, `features/*/presentation/screens|widgets`.
- **Règles :** couleurs et typographie uniquement via le thème (pas de couleur en dur dans un écran) ; composants partagés réutilisés ; widgets `const` ; écrans responsives (petits Android) ; états chargement / vide / erreur pour chaque écran ; textes en français.
- **Ne fait pas :** appeler l'API directement ; il consomme des providers.
- **Terminé quand :** l'écran correspond à la maquette, avec un widget test de rendu de base.

## 4. `api-integration` : intégration backend

**Mission :** couche `data` : DTO, datasources, repositories, client HTTP.

- **Responsable de :** `lib/core/network/`, `lib/core/storage/`, `features/*/data/`, `features/*/domain/` (contrats).
- **Règles :** Dio avec `AuthInterceptor` (ajout du JWT, refresh sur 401, déconnexion si échec) ; erreurs converties en `ApiException` typées (réseau, 400 validation, 403 droits, 404, 409 conflit de places) ; DTO `freezed` + `json_serializable` ; mapping DTO → entité ; tokens dans `flutter_secure_storage` uniquement. En l'absence d'API, utiliser des **datasources mock** derrière la même interface.
- **Terminé quand :** chaque repository a des tests unitaires (succès + erreurs).

## 5. `auth-kyc` : authentification, KYC, véhicule

**Mission :** sprints S1–S2 : splash, inscription, connexion, OTP SMS, parcours KYC, déclaration du véhicule, guards d'accès.

- **Responsable de :** `features/auth`, `features/kyc`, `features/vehicle`, guards dans `core/router`.
- **Règles :** OTP SMS à 6 chiffres avec compte à rebours de renvoi ; numéro au format `+228` ; KYC passager (identité recto/verso, selfie, photo de profil) et KYC conducteur (+ permis, carte grise ou assurance, photo du véhicule) ; statuts `non_verifie → en_attente → verifie | rejete` avec affichage du motif et nouvelle soumission ; pièces envoyées en multipart puis supprimées du cache local ; guards selon `claude.md` §3.
- **Attention :** le mode d'authentification (téléphone seul ou email/Google) est en attente (PRD §14). Isoler la méthode dans le repository pour pouvoir changer sans toucher l'UI.

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
- **Terminé quand :** les critères CA1–CA6 du PRD concernés sont couverts par des tests.

## 7. `qa-tester` : qualité et tests

**Mission :** garantir la non-régression et la couverture des critères d'acceptation.

- **Responsable de :** `test/` (unit, widget), plus tard `integration_test/`.
- **Règles :** un test par critère d'acceptation (CA1–CA6) ; tests des providers avec `ProviderContainer` et repositories mockés (`mocktail`) ; widget tests des écrans clés ; tests des guards (non vérifié, KYC en attente, suspendu) ; vérifier que le code de départ n'apparaît dans aucune vue conducteur.
- **Livrable :** rapport des tests ajoutés et des cas non couverts.

---

## Enchaînement type d'une fonctionnalité

```
prd-guardian (périmètre OK ?)
   → flutter-architect (squelette si nouvelle feature)
   → api-integration (domain + data, mock si API absente)
   → auth-kyc | booking-flow (providers + logique d'écran)
   → ui-figma-integrator (écran fidèle Figma)
   → qa-tester (tests CA)
   → prd-guardian (revue finale)
```

## Correspondance sprints → agents

| Sprint | Agent principal | Support |
|---|---|---|
| S0 Socle | flutter-architect | ui-figma-integrator, api-integration |
| S1 Auth | auth-kyc | api-integration, ui-figma-integrator |
| S2 KYC + Véhicule | auth-kyc | api-integration, ui-figma-integrator |
| S3 Recherche | booking-flow | api-integration, ui-figma-integrator |
| S4 Réservation passager | booking-flow | qa-tester |
| S5 Conducteur | booking-flow | qa-tester |
| S6 Après trajet | booking-flow | qa-tester |
| S7 Qualité | qa-tester | prd-guardian |
