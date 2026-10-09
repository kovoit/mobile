# Contrat API — KYC (Sprint S2)

Base : `/api/v1`. Authentification JWT requise. Validation **manuelle** par l'administrateur (MVP).

Retour UX du 08/10 : le KYC ne bloque plus l'inscription. Il se fait depuis l'écran **Profil**. Tant qu'il n'est pas `verifie`, le backend refuse (403) la réservation, la publication et le passage en mode conducteur.

## Objet `dossier`

```json
{
  "type": "passager",
  "statut": "rejete",
  "motif_rejet": "Photo de la pièce illisible.",
  "pieces": [
    { "type_piece": "photo_profil", "fournie": true },
    { "type_piece": "identite_recto", "fournie": true },
    { "type_piece": "identite_verso", "fournie": false },
    { "type_piece": "selfie", "fournie": false }
  ]
}
```

- `type` : `passager` | `conducteur`.
- `statut` : `non_verifie` → `en_attente` → `verifie` | `rejete`. Un dossier `rejete` porte `motif_rejet` et redevient modifiable.
- Pièces attendues, **dans cet ordre** (ordre d'affichage de la maquette « Vérification d'identité ») :

| Dossier | Pièces |
|---|---|
| passager | `photo_profil`, `identite_recto`, `identite_verso`, `selfie` |
| conducteur | `permis`, `carte_grise_ou_assurance`, `photo_vehicule` |

## Endpoints

| Méthode | Chemin | Corps | Réponse | Erreurs |
|---|---|---|---|---|
| GET | `/kyc/dossiers/` | — | 200 `[dossier passager, dossier conducteur]` (créés à `non_verifie` s'ils n'existent pas) | 401 |
| POST | `/kyc/dossiers/{type}/pieces/` | multipart : `type_piece`, `fichier` (JPEG, ≤ 5 Mo) | 200 `dossier` | 400 type de pièce invalide ou fichier refusé · 409 dossier `en_attente` / `verifie` (non modifiable) |
| POST | `/kyc/dossiers/{type}/soumettre/` | — | 200 `dossier` (`en_attente`) | 400 pièces manquantes · 403 dossier `conducteur` alors que le dossier `passager` est `non_verifie` |

Un nouvel envoi d'une pièce déjà fournie la **remplace**.

## Règles serveur

- Les pièces sont des données sensibles : stockage privé (pas d'URL publique), accès réservé à l'administrateur, journalisation de chaque consultation.
- Après décision de l'administrateur (`verifie` / `rejete` + motif) : notification push à l'utilisateur, et mise à jour de `kyc_passager` / `kyc_conducteur` dans l'objet `user`.
- Le dossier conducteur ne peut être soumis qu'après l'envoi du dossier passager (les pièces d'identité du passager en font partie).

## Côté mobile

- Le fichier capturé est supprimé de l'appareil après l'envoi, que celui-ci réussisse ou non.
- Le selfie se prend uniquement en direct (caméra frontale), jamais depuis la galerie.
