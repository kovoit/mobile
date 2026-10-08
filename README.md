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
- « Continuer avec Google » simule un compte sans numéro (écran de saisie du numéro).

Pour viser le vrai backend : `--dart-define=USE_MOCK_API=false` (contrat : [docs/api/auth.md](docs/api/auth.md)).

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
