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
flutter build apk --dart-define=ENV=prod   --dart-define=TILE_URL='https://<fournisseur>/{z}/{x}/{y}.png?key=<clé>'   --dart-define=TILE_ATTRIBUTION='© <fournisseur> © OpenStreetMap'
```

Cartes : sans `TILE_URL`, l'app utilise les serveurs publics d'OpenStreetMap, acceptables en
développement seulement (leurs conditions interdisent un usage intensif). En production, fournir
l'URL d'un fournisseur de tuiles et son attribution (affichée en bas de chaque carte).

En environnement `dev`, l'onglet **Profil** donne accès au **catalogue des composants** (`/dev/composants`).

## API simulée (dev)

Tant que le backend n'est pas prêt, `flutter run` utilise une fausse API en mémoire :

- connexion sans mot de passe : saisir `demo@kovoit.tg` (passager) ou `conducteur@kovoit.tg` (conducteur), puis le code `123456` ;
- toute autre adresse crée un nouveau compte, qui passe par l'écran « Votre profil » (prénom, nom, téléphone) ;
- le compte démo a un KYC passager validé ; un nouvel inscrit arrive sans KYC (macaron orange dans le Profil) ;
- Profil → « Mode démo » : **Valider / Refuser les dossiers** simule la décision de l'administrateur (KYC en attente) ;
- recherche de démo : **Carrefour Franciscain → Université de Lomé**, en voiture vers **07:30** (3 trajets) ou en moto vers 07:35. Autres trajets : Agoè-Zongo → Grand Marché (07:15), Bè Kpota → Port (moto, 08:00), Baguida → Déckon (17:30). Fenêtre de ± 15 min.

- réservation de démo : sur « Détails & Réservation », choisir Espèces ou Flooz / Mixx puis « Réserver ma place ». Sur l'écran de suivi, le bloc **Mode démo** joue le conducteur (**Accepter**, **Refuser**, **Saisir le code**). Le paiement Flooz / Mixx passe « en cours » puis « Payé » quelques secondes plus tard.

- conducteur de démo : `conducteur@kovoit.tg` (mode conducteur, Toyota Yaris, 18 500 F d'économies ce mois). À chaque publication, deux passagers fictifs envoient une demande ; leur code de départ est `4821`.

## Vrai backend (`kovoit/backend`)

```bash
# côté backend : écouter sur toutes les interfaces et ajouter l'IP du PC à ALLOWED_HOSTS (.env)
python manage.py runserver 0.0.0.0:8000
# côté mobile, téléphone sur le même Wi-Fi (IP du PC : ipconfig)
flutter run --dart-define=USE_MOCK_API=false --dart-define=API_BASE_URL=http://192.168.1.20:8000/api/v1
# ou via ngrok
flutter run --dart-define=USE_MOCK_API=false --dart-define=API_BASE_URL=https://xxxx.ngrok-free.app/api/v1
```

URL et chemins : [lib/core/constants/api_constants.dart](lib/core/constants/api_constants.dart). Client : [lib/core/network/api_service.dart](lib/core/network/api_service.dart) (enveloppe `{statut, message, reponse}`, JWT + rafraîchissement avec rotation). HTTP en clair autorisé en debug/profile uniquement (`android/app/build.gradle.kts`).

Anciens contrats mobiles (à réaligner sur le backend) : [auth](docs/api/auth.md), [KYC](docs/api/kyc.md), [véhicule](docs/api/vehicle.md), [recherche & trajets](docs/api/trips.md), [réservations & paiement](docs/api/bookings.md), [espace conducteur](docs/api/driver.md), [après le trajet & notifications](docs/api/after_trip.md).

## Notifications push (à configurer avant la mise en production)

Sans configuration, l'app fonctionne : la cloche relit `/notifications/` à l'ouverture, au retour au premier plan et toutes les 60 s. Pour activer le push FCM :

1. Créer un projet Firebase, y ajouter l'app Android `com.kovoit.kovoit` (et l'app iOS).
2. Placer `google-services.json` dans `android/app/` et `GoogleService-Info.plist` dans `ios/Runner/` (ou lancer `flutterfire configure`).
3. Ajouter le plugin Gradle `com.google.gms.google-services` (Android) et activer *Push Notifications* + *Background Modes › Remote notifications* dans Xcode (iOS, clé APNs à téléverser dans Firebase).
4. Lancer avec `--dart-define=PUSH_ENABLED=true`. Le backend envoie les push avec le compte de service Firebase (voir [docs/api/after_trip.md](docs/api/after_trip.md)).

Mode démo : sur l'écran de suivi, **Terminer le trajet** (bloc « Mode démo ») permet de tester la confirmation d'arrivée, la notation et le signalement.

## Structure

```
lib/
├── core/        config, network (Dio + JWT), storage, router, theme, widgets, utils
└── features/    auth, kyc, vehicle, search, trip, booking, driver, rating, report, profile, shell
                 (chacune : data / domain / presentation)
```
