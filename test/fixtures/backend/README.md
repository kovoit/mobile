# Réponses réelles du backend (test de contrat)

Ces fichiers sont produits par le **vrai** backend Django (ses serializers), pas écrits à la main.
`test/core/network/api_contract_test.dart` fait tourner les sources de données réelles de l'app
(`Api…RemoteDataSource`) sur ces réponses : si l'API change, le test échoue avant la mise en production.

Régénérer après un changement d'API (dans `backend/`) :

```bash
KOVOIT_CONTRAT=../mobile/test/fixtures/backend pytest apps/core/tests/contrat_mobile.py
```

puis, dans `mobile/` :

```bash
flutter test test/core/network/api_contract_test.dart
```

Les identifiants (UUID) et les dates changent à chaque génération : c'est normal.

**Exception provisoire (M-003, F-057)** : `trajet_detail_trace.json` est écrit à la main d'après le
contrat C1 (`pilotage/missions/M-003-demo-trace-filtre-photo.md`), en attendant que le backend
renvoie `trace` dans le détail. À remplacer par une fixture régénérée dès la route livrée.

**Exception provisoire (M-003, F-003)** : `moi_photo.json` et `erreur_photo.json` sont écrits à la
main d'après le contrat C3 et `ProfilSerializer` (`backend/apps/accounts/api/serializers.py`), avec
`photo` en chemin **relatif** (`/media/…`), comme toutes les routes du backend (décision Q1 révisée :
le mobile complète le chemin avec l'origine de l'API, `lib/core/network/media_url.dart`).
`trajet_detail_photo.json` est `trajet_detail.json` avec une photo relative pour le conducteur et le
véhicule (les données de démo n'en ont pas). À remplacer par des fixtures régénérées dès que le
script du backend couvre ces cas (`PATCH /moi/` avec photo, le même envoi avec un fichier qui n'est
pas une image, détail d'un trajet dont le conducteur a une photo).
