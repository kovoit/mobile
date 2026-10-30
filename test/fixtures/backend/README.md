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
