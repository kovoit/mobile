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

- connexion par e-mail + mot de passe (D-68) : `demo@kovoit.tg` (passager) ou `conducteur@kovoit.tg` (conducteur) ; mot de passe dans [lib/core/config/demo_account.dart](lib/core/config/demo_account.dart) (`DemoAccount.password`), rappelé sur l'écran de connexion en démo. Le code `123456` ne sert plus qu'à la vérification de l'e-mail et à « Mot de passe oublié » ;
- nouveau compte : « Créer un compte » (prénom, nom, e-mail, téléphone, mot de passe, CGU), puis code `123456` pour vérifier l'e-mail ; une adresse inconnue est refusée à la connexion ;
- le compte démo a un KYC passager validé ; un nouvel inscrit arrive sans KYC (macaron orange dans le Profil) ;
- Profil → « Mode démo » : **Valider / Refuser les dossiers** simule, sur clic, la décision de l'administrateur KYC sur les dossiers en attente. C'est la seule simulation d'un autre rôle conservée : la démo ne joue jamais le conducteur ni le passager ;
- recherche de démo : **Carrefour Franciscain → Université de Lomé**, en voiture vers **07:30** (3 trajets) ou en moto vers 07:35. Autres trajets : Agoè-Zongo → Grand Marché (07:15), Bè Kpota → Port (moto, 08:00), Baguida → Déckon (17:30). Fenêtre de ± 15 min.

- réservation de démo : sur « Détails & Réservation », « Réserver ma place ». La place est payée par le portefeuille (montant bloqué à la demande ; pas d'espèces, D-23) ; s'il manque de l'argent, recharger d'abord le portefeuille par Flooz / Mixx (recharge simulée en démo). La démo ne joue pas le conducteur : la demande reste « En attente » (parcours complet : voir [Tester un trajet complet](#tester-un-trajet-complet-sur-le-vrai-backend)).

- conducteur de démo : `conducteur@kovoit.tg` (mode conducteur, Toyota Yaris, 18 500 F d'économies ce mois). En démo, un trajet publié reste sans demande : la recherche de démo ne propose que les trajets fixes ci-dessus, jamais ceux publiés par le conducteur. Parcours complet sur le vrai backend (voir [Tester un trajet complet](#tester-un-trajet-complet-sur-le-vrai-backend)). `FakeDriver.simulatePassengerRequests` (code de départ `4821`) sert aux tests uniquement.

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

## APK de production (Android)

L'APK release est signée avec la clé de production lue dans `android/key.properties`. Ce fichier et la clé (`*.jks`) ne sont **jamais** commités. Sans eux, l'APK est signée avec la clé de debug : à réserver aux tests.

1. Créer la clé, **une seule fois** (keytool est fourni avec Android Studio / le JDK) :
   ```bash
   keytool -genkey -v -keystore ~/kovoit-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias kovoit
   ```
2. Créer `android/key.properties` :
   ```properties
   storeFile=C:/chemin/vers/kovoit-upload.jks
   storePassword=<mot de passe de la clé>
   keyAlias=kovoit
   keyPassword=<mot de passe de la clé>
   ```
3. Construire (augmenter `version:` dans `pubspec.yaml` à chaque nouvelle version, ex. `1.0.1+2`) :
   ```bash
   flutter build apk --release --dart-define=ENV=prod
   ```
   APK : `build/app/outputs/flutter-apk/app-release.apk`.

**Garder la clé et ses mots de passe en lieu sûr (2 copies hors de l'ordinateur).** Sans elle, aucune mise à jour de l'app ne pourra être installée par-dessus la version existante : les utilisateurs devraient désinstaller puis réinstaller.

## Notifications push (à configurer avant la mise en production)

Sans configuration, l'app fonctionne : la cloche relit `/notifications/` à l'ouverture, au retour au premier plan et toutes les 60 s. Pour activer le push FCM :

1. Créer un projet Firebase, y ajouter l'app Android `com.kovoit.kovoit` (et l'app iOS).
2. Placer `google-services.json` dans `android/app/` et `GoogleService-Info.plist` dans `ios/Runner/` (ou lancer `flutterfire configure`).
3. Ajouter le plugin Gradle `com.google.gms.google-services` (Android) et activer *Push Notifications* + *Background Modes › Remote notifications* dans Xcode (iOS, clé APNs à téléverser dans Firebase).
4. Lancer avec `--dart-define=PUSH_ENABLED=true`. Le backend envoie les push avec le compte de service Firebase (voir [docs/api/after_trip.md](docs/api/after_trip.md)).

## Tester un trajet complet sur le vrai backend

Le mode démo ne joue jamais le conducteur ni le passager. Acceptation, code de départ, absence, partage de position, fin du trajet, confirmation d'arrivée, notation et signalement se testent sur le vrai backend :

- deux comptes (un conducteur, un passager) et deux téléphones ;
- l'app lancée sur chaque téléphone avec `--dart-define=USE_MOCK_API=false --dart-define=API_BASE_URL=http://<IP du PC>:8000/api/v1` ;
- le temps avancé côté serveur par `python manage.py avancer_trajet`.

Comptes de test, commandes et scénario pas à pas : [backend/README.md](../backend/README.md), section « Tester un trajet complet avec deux téléphones ».

## Structure

```
lib/
├── core/        config, network (Dio + JWT), storage, router, theme, widgets, utils
└── features/    auth, kyc, vehicle, search, trip, booking, driver, rating, report, profile, shell
                 (chacune : data / domain / presentation)
```
