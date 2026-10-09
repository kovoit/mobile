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
| Photos KYC | `image_picker` (selfie : caméra frontale uniquement) ; contrats : [docs/api/kyc.md](docs/api/kyc.md), [docs/api/vehicle.md](docs/api/vehicle.md) |
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
│   ├── config/               # Env (dev/staging/prod), baseUrl, compte démo
│   ├── mock/                 # FakeBackend : API simulée partagée (JSON des contrats docs/api)
│   ├── network/              # DioClient, AuthInterceptor, ApiException, Result
│   ├── storage/              # SecureStorage (access/refresh tokens)
│   ├── router/               # app_router.dart, routes.dart, guards
│   ├── theme/                # couleurs, typographie, espacements, rayons
│   ├── widgets/              # composants partagés (voir §5)
│   └── utils/                # formatters (FCFA, dates), validators (téléphone +228)
└── features/
    ├── auth/                 # splash, connexion, inscription, OTP SMS, AccessPolicy (domain)
    ├── kyc/                  # dossier passager/conducteur, pièces, selfie, statut, carte « accès restreint »
    ├── vehicle/              # déclaration du véhicule
    ├── search/               # recherche, résultats, carte
    ├── trip/                 # détail d'un trajet, publication (conducteur)
    ├── booking/              # réservation, suivi, code de départ, annulation, confirmation
    ├── driver/               # espace conducteur, demandes, saisie code, absence, clôture, économies
    ├── rating/               # notation 1–5 ★
    ├── report/               # signalement
    ├── profile/              # profil (KYC, véhicule, macaron), bascule de mode, « Devenir conducteur »
    └── shell/                # BottomNav : Rechercher|Publier / Mes trajets / Profil, accueil selon le mode
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

## 3. Navigation et droits d'accès

### A. Cartographie des routes (`core/router/routes.dart`)

| Route | Écran | Accès |
|---|---|---|
| `/` | Splash (restauration de session) | tous |
| `/connexion`, `/inscription`, `/mot-de-passe-oublie` | Auth (S1) | déconnecté uniquement |
| `/telephone`, `/verification-sms` | Saisie du numéro, OTP SMS | connecté, téléphone non vérifié |
| `/accueil` *(onglet 1)* | Passager : « Rechercher un trajet » · Conducteur : « Espace Conducteur » | téléphone vérifié |
| `/mes-trajets` *(onglet 2)* | Réservations / trajets publiés (S4) | téléphone vérifié |
| `/profil` *(onglet 3)* | Profil : KYC, véhicule, bascule de mode, macaron orange | téléphone vérifié |
| `/profil/verification/:type` | KYC `passager` ou `conducteur` (plein écran) | téléphone vérifié |
| `/profil/verification/:type/envoye` | « Dossier envoyé » / « Profil vérifié » | téléphone vérifié |
| `/profil/vehicule` | Déclaration du véhicule | téléphone vérifié |
| `/profil/devenir-conducteur` | Check-list avant le mode conducteur | téléphone vérifié |
| `/dev/composants` | Catalogue des composants | dev uniquement |

Les redirections passent **toutes** par `core/router/auth_guard.dart` (fonction pure, testée). Le routeur ne se réévalue que si un champ utile à la garde change (session, téléphone), pas à chaque rafraîchissement de l'utilisateur.

### B. Droits d'accès (`features/auth/domain/access_policy.dart`)

Le **KYC ne bloque plus la navigation** (retour UX du 08/10) : il se fait depuis le Profil. Les droits sont contrôlés **au moment de l'action** par `AccessPolicy` (et par le backend : 403).

| État de l'utilisateur | Accès mobile |
|---|---|
| Non connecté | Splash, connexion, inscription uniquement (le lien « Partager mon trajet » est une page web publique, pas l'app) |
| Téléphone vérifié (OTP) | Toute l'application ; carte « accès restreint » sur l'accueil, macaron orange sur Profil tant que le KYC passager est `non_verifie` / `rejete` |
| KYC passager `verifie` | Réserver une place (`AccessPolicy.canBook`) |
| KYC passager + conducteur `verifie` + véhicule déclaré | « Passer en mode conducteur », publier (`canSwitchToDriver` / `canPublish`) ; sinon → `/profil/devenir-conducteur` |
| Compte `suspendu` | Ni réserver, ni publier, ni changer de mode ; message avec `suspendu_jusqu_au` |

Statuts KYC : `non_verifie` → `en_attente` → `verifie` | `rejete` (avec `motif_rejet`, nouvelle soumission possible). Le dossier conducteur ne s'ouvre qu'après l'envoi du dossier passager.

Tout nouvel écran avec une action sensible (réserver, publier) affiche `AccessRequiredCard` / désactive l'action quand `AccessPolicy` renvoie une `AccessDenial`.

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
- **Typographie** : titres d'en-tête (`AppTextStyles.display`) à **24 px** (réduits de 28 px, retour UX du 08/10) ; ne pas les agrandir écran par écran.
- **Composants partagés** (`core/widgets/`) : `KovoitAppBar` (retour + logo + badge « Lomé »), `PrimaryButton`, `SegmentedToggle` (Connexion/Inscription, Moto/Voiture), `KovoitTextField` (icône), `OtpCodeInput` (6 cases), `VerifiedBadge`, `StatusChip`, `InfoBanner`, `RatingLabel`, `DriverCard`, `PriceTag`, `PlaceStepper` (− n +), `StepProgress`, `MapPreview`.
- **Bascule de mode** : uniquement dans le Profil (bouton « Passer en mode conducteur / passager »). Ne pas reproduire le toggle Passager/Conducteur de la maquette « Espace Conducteur ».
- **Macaron orange** (`AppColors.accent`) : action attendue de l'utilisateur (KYC), sur l'onglet Profil et la ligne concernée.
- **Deux codes à ne pas confondre** : OTP SMS à **6 chiffres** (vérification du téléphone) ≠ code de départ à **4 chiffres** (prise en charge).
- **Paiement mobile** : libellés **Flooz** (Moov Africa) et **Mixx** (Togocom). Ne jamais afficher « T-Money ». Le traitement réel reste soumis à D5/D7 (PRD §14).
- Bouton « Message » de la maquette : hors MVP (D4), ne pas implémenter de logique.

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

**API simulée** (`Env.useMockApi`, active par défaut en dev, jamais en prod) : chaque feature fournit une fausse datasource branchée sur le `FakeBackend` partagé (`core/mock`), qui respecte les contrats de `docs/api/` et les règles serveur (statuts KYC, droits du mode conducteur). Les écrans n'en savent rien, seul le provider de datasource change. Démo : `demo@kovoit.tg` / `kovoit123` (KYC passager validé), OTP `123456`. Dans le Profil, des boutons « Valider / Refuser les dossiers » simulent la décision de l'administrateur.

**Tests** : `test/helpers/test_app.dart` fournit `pumpKovoitApp`, `TestEnv` (`demoSession()`, `newUserSession()`, backend sans latence, caméra simulée) et `scrollAndTap`. Aucune vraie entrée/sortie disque ou réseau dans les tests de widgets : passer par un service injectable.

---

## 7. Décisions en attente (ne pas trancher seul)

Ces points sont contradictoires entre la spécification, le PRD et les maquettes. **Ne rien implémenter qui présuppose une réponse** ; demander à l'équipe.

1. Calcul du prix : grille 200/300/500 F par distance (spéc.), aucun prix (PRD), ou formule au km (ancienne version de ce fichier). Dans tous les cas, le mobile **affiche** le prix renvoyé par l'API.
2. Frais de service Kovoit : 0 F pendant le pilote (spéc., maquettes) ou 10 %.
3. ~~Authentification~~ → **tranché** : e-mail + mot de passe ou Google, puis OTP SMS.
4. Bouton « Message » (hors MVP selon la spéc.). Paiement mobile : libellés tranchés (Flooz / Mixx), traitement réel en attente (D5/D7).
5. Backend : DRF seul ou DRF + FastAPI.
6. Paiement : espèces uniquement pour le MVP ?

Les paramètres administrateur (prix du litre, rayons, délais, seuils) sont décrits dans le PRD §10 et ne concernent le mobile qu'en lecture.
