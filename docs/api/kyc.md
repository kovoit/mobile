# Contrat API — KYC (backend `kovoit/backend`, app `kyc`)

Base : `/api/v1`. JWT requis. Réponses enveloppées `{statut, message, reponse}`. Validation **manuelle** par l'administrateur.

Retour UX du 08/10 : le KYC ne bloque pas l'inscription. Il se fait depuis le **Profil**. Tant qu'il n'est pas `verifie`, le backend refuse (403) la réservation, la publication et le passage en mode conducteur.

## Objet `dossier` (`DossierSerializer`)

```json
{
  "id": "…", "type": "conducteur", "statut": "rejete",
  "motif_rejet": "Photo de la pièce illisible.", "soumis_le": "…", "traite_le": "…",
  "pieces": [ { "id": "…", "type_piece": "identite", "cree_le": "…" }, { "id": "…", "type_piece": "assurance", "cree_le": "…" } ],
  "pieces_manquantes": ["permis", "photo_vehicule", "selfie"]
}
```

- `statut` : `non_verifie` → `en_attente` → `verifie` | `rejete`. Un dossier `rejete` porte `motif_rejet` (chaîne vide sinon) et redevient modifiable.
- `pieces_manquantes` : emplacements vides. `carte_grise_ou_assurance` signale le document du véhicule manquant.

| Dossier | Pièces obligatoires |
|---|---|
| passager | `identite`, `selfie` |
| conducteur | `identite`, `selfie`, `permis`, `photo_vehicule` + `carte_grise` **ou** `assurance` |

> Le dossier conducteur redemande l'identité et le selfie : les pièces du dossier passager ne sont pas réutilisées par le backend, et le mobile ne garde aucune pièce sur l'appareil.

## Endpoints

| Méthode | Chemin | Corps | Réponse | Erreurs |
|---|---|---|---|---|
| GET | `/kyc/` | — | `[dossier passager, dossier conducteur]` (créés à `non_verifie`) | 401 |
| POST | `/kyc/{type}/pieces/` | multipart : `type_piece`, `fichier` (JPEG, PNG ou PDF, ≤ 5 Mo) | 201 `dossier` | 400 pièce non demandée, fichier trop gros ou mauvais format · 409 `DOSSIER_NON_MODIFIABLE` |
| POST | `/kyc/{type}/soumettre/` | — | `dossier` (`en_attente`) | 403 `PROFIL_INCOMPLET` · 400 `DOSSIER_INCOMPLET` (`erreurs.pieces_manquantes`) · 409 `DOSSIER_NON_MODIFIABLE` |

Un nouvel envoi d'une pièce déjà fournie la **remplace**.

## Côté mobile

- Emplacements affichés (`KycSlot`, dans cet ordre) : identité, selfie, permis, carte grise ou assurance, photo du véhicule. Seuls ceux présents dans `pieces` ou `pieces_manquantes` sont affichés.
- Pour « carte grise ou assurance », l'utilisateur choisit d'abord le document qu'il envoie.
- Le fichier capturé est supprimé de l'appareil après l'envoi, que celui-ci réussisse ou non.
- Le selfie se prend uniquement en direct (caméra frontale), jamais depuis la galerie.
- Ordre conseillé (règle d'interface, non imposée par le backend) : le dossier conducteur s'ouvre une fois le dossier passager envoyé.
