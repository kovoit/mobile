# Contrat API — Véhicule (Sprint S2)

Base : `/api/v1`. Authentification JWT requise. Un seul véhicule par conducteur dans le MVP.

## Objet `vehicule`

```json
{
  "id": 12,
  "type": "voiture",
  "marque": "Toyota",
  "modele": "Yaris",
  "couleur": "Gris",
  "immatriculation": "TG 4827 AU",
  "nb_places": 5,
  "statut_verification": "en_attente"
}
```

- `type` : `moto` | `voiture`.
- `nb_places` : places **totales, conducteur compris** (moto : 2 ; voiture : 2 à 9). À la publication d'un trajet, les places proposées sont ≤ `nb_places − 1`.
- `statut_verification` (lecture seule) : `en_attente` | `verifie` | `rejete`. La **photo du véhicule** est une pièce du dossier KYC conducteur (`photo_vehicule`, voir [kyc.md](kyc.md)).

## Endpoints

| Méthode | Chemin | Corps | Réponse | Erreurs |
|---|---|---|---|---|
| GET | `/vehicules/moi/` | — | 200 `vehicule` | 404 aucun véhicule déclaré |
| PUT | `/vehicules/moi/` | `type`, `marque`, `modele`, `couleur`, `immatriculation`, `nb_places` | 200 `vehicule` (création ou mise à jour) | 400 erreurs par champ (`nb_places`, `immatriculation` déjà utilisée…) |

Après un `PUT` réussi, `user.vehicule_declare` vaut `true`. Une modification de l'immatriculation repasse `statut_verification` à `en_attente`.
