# Contrat API — Réservations et paiement (Sprint S4)

Base : `/api/v1`. JWT requis. Réserver exige un **KYC passager `verifie`** et un compte actif (403 sinon).

**Décision D5/D7 (09/10/2026) :** le passager choisit son moyen de paiement à la réservation : **Espèces**, **Flooz** (Moov Africa) ou **Mixx** (Togocom).

| Méthode | Quand payer | Rôle de Kovoit |
|---|---|---|
| `especes` | Au conducteur, en main propre, à la prise en charge | Enregistre le montant dû (économies du conducteur) |
| `flooz` / `mixx` | Après l'**acceptation** du conducteur, depuis l'app | Encaisse via l'agrégateur, rembourse si annulation ou refus, verse au conducteur à la clôture |

## Objet `reservation`

```json
{
  "id": 501,
  "trajet": { "…": "trajet_resume, voir trips.md" },
  "nb_places": 1,
  "point_prise_en_charge_id": 101,
  "statut": "acceptee",
  "code_depart": "4821",
  "prix_total": 300,
  "frais_service": 0,
  "paiement": {
    "methode": "flooz",
    "statut": "en_attente",
    "montant": 300,
    "telephone": "+22896123456",
    "reference": "FLZ-8843120",
    "message": "Validez le paiement sur votre téléphone (code secret Flooz)."
  },
  "annulation_gratuite_jusqu_au": "2026-10-08T07:00:00Z",
  "annulation_tardive": false,
  "conducteur_telephone": "+22890000101",
  "position_conducteur": { "lat": 6.1655, "lng": 1.1702, "maj_le": "2026-10-08T07:26:00Z" },
  "arrivee_conducteur_min": 3,
  "actions": ["annuler", "payer", "partager", "appeler"],
  "cree_le": "2026-10-08T06:40:00Z"
}
```

| Champ | Règle |
|---|---|
| `statut` | 9 statuts : `demandee`, `acceptee`, `refusee`, `annulee`, `absent`, `en_cours`, `terminee`, `litige`, `cloturee` |
| `code_depart` | 4 chiffres, **présent uniquement pour le passager**, et uniquement en `acceptee`. Jamais renvoyé au conducteur, jamais journalisé. Stocké haché côté serveur, sauf la valeur affichée au passager |
| `paiement.statut` | `non_requis` (espèces), `a_payer`, `en_attente` (demande envoyée à l'opérateur), `reussi`, `echoue`, `rembourse` |
| `annulation_gratuite_jusqu_au` | départ − `delai_annulation_min`. Au-delà, l'annulation compte comme **tardive** (fiabilité). Calculé par le serveur |
| `conducteur_telephone` | Seulement en `acceptee` / `en_cours` (vie privée) |
| `position_conducteur`, `arrivee_conducteur_min` | Seulement en `acceptee`, quand l'app conducteur partage sa position (S5) ; sinon `null` |
| `actions` | Actions autorisées **maintenant** pour l'appelant. Le mobile n'affiche que celles-ci |

## Endpoints

| Méthode | Chemin | Corps | Réponse | Erreurs |
|---|---|---|---|---|
| POST | `/reservations/` | `trajet_id`, `nb_places`, `point_prise_en_charge_id`, `methode_paiement` | 201 `reservation` (`demandee`) | 400 · 403 KYC / suspendu · 409 plus assez de places ou déjà une demande sur ce trajet |
| GET | `/reservations/` | `?role=passager` | 200 `[reservation]` (récentes d'abord) | — |
| GET | `/reservations/{id}/` | — | 200 `reservation` | 404 |
| POST | `/reservations/{id}/annuler/` | `motif` (optionnel) | 200 `reservation` (`annulee`, `annulation_tardive` renseigné) | 409 action impossible dans ce statut |
| POST | `/reservations/{id}/paiement/` | `telephone` (Flooz ou Mixx, E.164) | 200 `reservation` (`paiement.statut` = `en_attente`) | 400 numéro invalide pour l'opérateur · 409 rien à payer |
| POST | `/reservations/{id}/partage/` | — | 200 `{ "url": "https://kovoit.tg/t/…", "expire_le": "…" }` | 409 hors `acceptee` / `en_cours` |

Le statut du paiement est confirmé par le **webhook de l'agrégateur** côté serveur. Le mobile relit la réservation (toutes les 3 s pendant `en_attente`, 2 min maximum).

## Règles serveur

- À l'acceptation : `places_restantes` −1 (verrou `select_for_update`), génération du code de départ, notification au passager.
- Refus / annulation : place rendue ; paiement mobile `reussi` → `rembourse`.
- Chaque changement de statut notifie l'autre partie (push, SMS si l'app est fermée) : S6.
- Lien de partage : public, temporaire, valable jusqu'à la clôture, position du véhicule seulement.

## Questions encore ouvertes (PRD §14)

- Agrégateur retenu (PayGate Global, FedaPay, CinetPay) et qui paie les frais de transaction.
- Paiement mobile non effectué avant le départ : rappel, ou bascule en espèces ?

## Mode mock

- « Réserver » crée une demande `demandee`. Sur l'écran de suivi, des boutons de démo simulent le conducteur : **Accepter**, **Refuser**, **Démarrer** (code saisi).
- Paiement Flooz / Mixx : `en_attente`, puis `reussi` à la relecture suivante.
