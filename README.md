# Kovoit — application mobile

Covoiturage urbain à Lomé : *« Même trajet, moins cher »*. Application Flutter (passager + conducteur).

- Règles de développement : [claude.md](claude.md)
- Besoins fonctionnels : [PRD.md](PRD.md)
- Rôles des agents : [agents.md](agents.md)
- Sources : `docs/` (spécification MVP, maquettes Figma)

## Démarrer

```bash
flutter pub get
flutter run                                   # ENV=dev, API http://10.0.2.2:8000/api/v1
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api/v1   # appareil physique
flutter analyze
flutter test
flutter build apk --dart-define=ENV=prod
```

En environnement `dev`, l'onglet **Profil** donne accès au **catalogue des composants** (`/dev/composants`).

## API simulée (dev)

Tant que le backend n'est pas prêt, `flutter run` utilise une fausse API en mémoire :

- compte de démo : `demo@kovoit.tg` / `kovoit123` ;
- code SMS : `123456` ;
- « Continuer avec Google » simule un compte sans numéro (écran de saisie du numéro) ;
- le compte démo a un KYC passager validé ; un nouvel inscrit arrive sans KYC (macaron orange dans le Profil) ;
- Profil → « Mode démo » : **Valider / Refuser les dossiers** simule la décision de l'administrateur (KYC en attente) ;
- recherche de démo : **Carrefour Franciscain → Université de Lomé**, en voiture vers **07:30** (3 trajets) ou en moto vers 07:35. Autres trajets : Agoè-Zongo → Grand Marché (07:15), Bè Kpota → Port (moto, 08:00), Baguida → Déckon (17:30). Fenêtre de ± 15 min.

- réservation de démo : sur « Détails & Réservation », choisir Espèces ou Flooz / Mixx puis « Réserver ma place ». Sur l'écran de suivi, le bloc **Mode démo** joue le conducteur (**Accepter**, **Refuser**, **Saisir le code**). Le paiement Flooz / Mixx passe « en cours » puis « Payé » quelques secondes plus tard.

- conducteur de démo : `conducteur@kovoit.tg` / `kovoit123` (mode conducteur, Toyota Yaris, 18 500 F d'économies ce mois). À chaque publication, deux passagers fictifs envoient une demande ; leur code de départ est `4821`.

Pour viser le vrai backend : `--dart-define=USE_MOCK_API=false`. Contrats : [auth](docs/api/auth.md), [KYC](docs/api/kyc.md), [véhicule](docs/api/vehicle.md), [recherche & trajets](docs/api/trips.md), [réservations & paiement](docs/api/bookings.md), [espace conducteur](docs/api/driver.md).

## Connexion Google (à configurer avant le vrai backend)

1. Google Cloud Console → créer un client OAuth **Web** (son ID = `GOOGLE_SERVER_CLIENT_ID`, audience vérifiée par le backend).
2. Créer un client OAuth **Android** : package `com.kovoit.kovoit` + empreinte SHA-1 (`cd android && ./gradlew signingReport`).
3. Lancer avec `--dart-define=GOOGLE_SERVER_CLIENT_ID=xxx.apps.googleusercontent.com`.

Sans cette configuration, le bouton Google affiche « La connexion Google n’est pas encore disponible ».

## Structure

```
lib/
├── core/        config, network (Dio + JWT), storage, router, theme, widgets, utils
└── features/    auth, kyc, vehicle, search, trip, booking, driver, rating, report, profile, shell
                 (chacune : data / domain / presentation)
```
