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
