# CLAUDE.md — Kovoit Mobile (MVP)

Kovoit : application mobile de covoiturage urbain à Lomé (Togo) basée sur le **partage des frais de carburant** (pas de profit, pas un service de taxi). Slogan : *« Même trajet, moins cher »*.

Ce dépôt contient **uniquement l'application mobile Flutter** (passager + conducteur). Le backend (Django REST Framework) et le back-office admin (React) vivent dans d'autres dépôts.

> **Règle d'or :** la source de vérité fonctionnelle est [PRD.md](PRD.md). En cas de conflit, `PRD.md` l'emporte sur le métier, `CLAUDE.md` sur la méthode de dev. Les rôles des agents sont décrits dans [agents.md](agents.md).
>
> **Sources :** `docs/Kovoit Spécification du MVP (1).docx` (spécification complète) et `docs/Nana Tech.zip` (11 maquettes Figma). À consulter avant tout écran ou toute règle métier.

## Stack

| Partie | Technologie |
|---|---|
| Mobile (ce dépôt) | Flutter (Dart 3, null-safety), Android en priorité |
| Gestion d'état | `flutter_riverpod` (+ `riverpod_annotation`) |
| Navigation | `go_router` avec guards |
| Réseau | `dio` + intercepteurs (JWT, refresh, erreurs) |
| Modèles | DTO `json_serializable` (code généré `*.g.dart`, versionné) ; entités `domain` écrites à la main, immuables (pas de `freezed` : seule une préversion est compatible avec Dart 3.12) |
| Authentification | E-mail + mot de passe ou Google (`google_sign_in` 7), puis OTP SMS — décision D3 ; contrat : [docs/api/auth.md](docs/api/auth.md) |
| Stockage sécurisé | `flutter_secure_storage` (tokens) |
| Cartographie | **OpenStreetMap gratuit** : `flutter_map` + `latlong2`, tuiles OSM ; itinéraires/distances fournis par le backend (OSRM) |
| Géolocalisation | `geolocator` |
| Photos KYC | `image_picker` / `camera` |
| Notifications | `firebase_messaging` (push) |
| Partage | `share_plus` (« Partager mon trajet ») |
| Formats | `intl` (FCFA, dates, fuseau `Africa/Lome`) |
| Backend consommé | Django REST Framework, JWT + OTP SMS, PostgreSQL/PostGIS |

---

## 1. Méthode & règles de développement

1. **Lire le PRD et le code existant** avant toute modification. Vérifier l'écran Figma correspondant.
2. **Rien de hors MVP** : pas de messagerie, pas de Mobile Money/portefeuille, pas de KYC automatique (OCR), pas de trajets interurbains, pas de trajets récurrents, pas d'IA.
3. **Aucune logique métier dans Flutter** : prix, frais de service, distance, correspondance des trajets, taux de fiabilité, transitions de statut sont **calculés par le backend**. Le mobile affiche les valeurs renvoyées par l'API et envoie des actions.
4. **Aucun paramètre métier en dur** (prix du litre, rayons, délais, seuils…). S'ils sont nécessaires à l'affichage, ils viennent de l'API.
5. **Code de départ (4 chiffres)** : affiché **uniquement** sur l'écran passager. Le conducteur ne fait que le **saisir**. Ne jamais le logger, le mettre en cache en clair ni l'envoyer dans des analytics.
6. **Données KYC sensibles** : envoi direct en multipart vers l'API, aucune copie persistante sur l'appareil après envoi, aucune URL publique.
7. **Montants** en F CFA entiers (`int`), formatés `300 FCFA`. Dates/heures affichées en `Africa/Lome`.
8. **Langue de l'UI** : français. Textes centralisés (prévoir `l10n` plus tard).
9. **Qualité** : `flutter analyze` sans warning et `flutter test` vert avant de considérer une tâche terminée.

---

## 2. Architecture Flutter (Clean Architecture par feature)

```
lib/
├── main.dart                 # bootstrap (env, ProviderScope)
├── app.dart                  # MaterialApp.router, thème
├── core/
│   ├── config/               # Env (dev/staging/prod), baseUrl
│   ├── network/              # DioClient, AuthInterceptor, ApiException, Result
│   ├── storage/              # SecureStorage (access/refresh tokens)
│   ├── router/               # app_router.dart, routes.dart, guards
│   ├── theme/                # couleurs, typographie, espacements, rayons
│   ├── widgets/              # composants partagés (voir §5)
│   └── utils/                # formatters (FCFA, dates), validators (téléphone +228)
└── features/
    ├── auth/                 # splash, connexion, inscription, OTP SMS
    ├── kyc/                  # dossier passager/conducteur, pièces, selfie, statut
    ├── vehicle/              # déclaration du véhicule
    ├── search/               # recherche, résultats, carte
    ├── trip/                 # détail d'un trajet, publication (conducteur)
    ├── booking/              # réservation, suivi, code de départ, annulation, confirmation
    ├── driver/               # espace conducteur, demandes, saisie code, absence, clôture, économies
    ├── rating/               # notation 1–5 ★
    ├── report/               # signalement
    ├── profile/              # profil, bascule de mode passager/conducteur
    └── shell/                # BottomNav : Rechercher / Mes trajets / Profil
```

Chaque feature suit :

```
features/<feature>/
├── data/          # dto/ (json_serializable), datasources/ (Dio + fausse API), repositories/, services/
├── domain/        # entités, repository abstrait (pas de dépendance Flutter/Dio)
└── presentation/  # screens/, widgets/, providers/ (Notifier/AsyncNotifier)
```

**Règles de dépendance :** `presentation → domain ← data`. Un écran n'appelle jamais Dio directement ; il passe par un provider → repository. Les features ne s'importent pas entre elles sauf via `domain` (entités partagées dans `core/` si besoin).

**Conventions :** fichiers `snake_case.dart`, classes `PascalCase`, un widget public par fichier, `const` partout où possible, pas de `print` (utiliser un logger).

---

## 3. Droits d'accès → guards de navigation

Le backend fait foi (403 = refus), le mobile anticipe pour l'UX :

| État de l'utilisateur | Accès mobile |
|---|---|
| Non connecté | Splash, connexion, inscription uniquement (le lien « Partager mon trajet » est une page web publique, pas l'app) |
| Téléphone vérifié (OTP) | Rechercher et consulter les trajets |
| KYC passager `verifie` | Réserver une place |
| KYC conducteur `verifie` + véhicule déclaré | Mode conducteur : publier un trajet |
| Compte `suspendu` | Ni réserver ni publier ; message explicatif avec date `suspendu_jusqu_au` |

Statuts KYC : `non_verifie` → `en_attente` → `verifie` | `rejete` (avec `motif_rejet`, nouvelle soumission possible).

---

## 4. Machines à états (affichage uniquement)

**Réservation, 9 statuts** (`demandee`, `acceptee`, `refusee`, `annulee`, `absent`, `en_cours`, `terminee`, `litige`, `cloturee`) :

```
demandee ──► acceptee ──► en_cours ──► terminee ──► cloturee
   │            │                         │            ▲
   ├► refusee   ├► annulee                └► litige ───┘
   └► annulee   └► absent
```

- `en_cours` : **uniquement** quand le conducteur saisit le bon code de départ.
- `absent` : déclaré par le conducteur depuis le point de prise en charge après l'heure de départ + tolérance (position GPS envoyée avec la déclaration).
- `cloturee` : confirmation du passager ou automatique après le délai configuré.

**Trajet :** `publie` → `complet` (places_restantes = 0) → `en_cours` → `termine` | `annule`.

Le mobile propose seulement les actions autorisées pour le statut courant, tel que renvoyé par l'API.

---

## 5. UI : fidélité aux maquettes Figma

- **Palette** (relevée sur les maquettes, à confirmer dans Figma) : bleu nuit primaire ≈ `#0F2A55`, orange accent ≈ `#F28C28`, vert « vérifié » ≈ `#22A85A`, fond ≈ `#F5F7FA`, cartes blanches à coins arrondis (~16 px).
- **Composants partagés** (`core/widgets/`) : `KovoitAppBar` (retour + logo + badge « Lomé »), `PrimaryButton`, `SegmentedToggle` (Connexion/Inscription, Moto/Voiture, Passager/Conducteur), `KovoitTextField` (icône), `OtpCodeInput` (6 cases), `VerifiedBadge`, `RatingLabel`, `DriverCard`, `PriceTag`, `PlaceStepper` (− n +), `StepProgress`, `MapPreview`.
- **Deux codes à ne pas confondre** : OTP SMS à **6 chiffres** (vérification du téléphone) ≠ code de départ à **4 chiffres** (prise en charge).
- Éléments visibles sur les maquettes mais **hors MVP** (bouton « Message », paiement « Mobile Money ») : en attente de décision (voir PRD §14), ne pas implémenter de logique.

---

## 6. Commandes

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # après toute modification d'un DTO
flutter analyze
flutter test
flutter run                                                # dev + API simulée
flutter run --dart-define=USE_MOCK_API=false --dart-define=GOOGLE_SERVER_CLIENT_ID=xxx.apps.googleusercontent.com
flutter build apk --dart-define=ENV=prod --dart-define=GOOGLE_SERVER_CLIENT_ID=...
```

**API simulée** (`Env.useMockApi`, active par défaut en dev, jamais en prod) : chaque feature fournit une fausse datasource en mémoire qui respecte le contrat de `docs/api/`. Les écrans n'en savent rien, seul le provider de datasource change. Démo : `demo@kovoit.tg` / `kovoit123`, OTP `123456`.

**Tests** : `test/helpers/test_app.dart` fournit `pumpKovoitApp` et `testOverrides()` (API simulée sans latence, stockage de jetons en mémoire).

---

## 7. Décisions en attente (ne pas trancher seul)

Ces points sont contradictoires entre la spécification, le PRD et les maquettes. **Ne rien implémenter qui présuppose une réponse** ; demander à l'équipe.

1. Calcul du prix : grille 200/300/500 F par distance (spéc.), aucun prix (PRD), ou formule au km (ancienne version de ce fichier). Dans tous les cas, le mobile **affiche** le prix renvoyé par l'API.
2. Frais de service Kovoit : 0 F pendant le pilote (spéc., maquettes) ou 10 %.
3. ~~Authentification~~ → **tranché** : e-mail + mot de passe ou Google, puis OTP SMS.
4. Boutons « Message » et « Mobile Money » des maquettes (hors MVP selon la spéc.).
5. Backend : DRF seul ou DRF + FastAPI.
6. Paiement : espèces uniquement pour le MVP ?

Les paramètres administrateur (prix du litre, rayons, délais, seuils) sont décrits dans le PRD §10 et ne concernent le mobile qu'en lecture.
