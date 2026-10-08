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

## Structure

```
lib/
├── core/        config, network (Dio + JWT), storage, router, theme, widgets, utils
└── features/    auth, kyc, vehicle, search, trip, booking, driver, rating, report, profile, shell
                 (chacune : data / domain / presentation)
```
