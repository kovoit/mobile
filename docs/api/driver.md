# Contrat API — Espace conducteur (Sprint S5)

Base : `/api/v1`. JWT requis. Toutes les routes exigent le **mode conducteur** : KYC passager + conducteur `verifie`, véhicule déclaré, compte actif (403 sinon).

## Estimer le prix avant publication

`POST /trajets/prix/` — `depart`, `arrivee`, `points_prise_en_charge` (objets `lieu`), `type_vehicule`

```json
{ "prix_place": 300, "distance_km": 8.4, "duree_min": 25 }
```

Le prix par place est **calculé par le backend** (décision D1 en attente : grille 200 / 300 / 500 F ou formule). Le mobile l'affiche (« Prix recommandé : 300 FCFA ») et ne le saisit jamais.

## Publier un trajet

`POST /trajets/`

```json
{
  "depart": { "libelle": "Carrefour Franciscain", "quartier": "Adidogomé", "lat": 6.166, "lng": 1.165 },
  "arrivee": { "libelle": "Université de Lomé · Entrée sud", "quartier": "Tokoin", "lat": 6.168, "lng": 1.214 },
  "points_prise_en_charge": [ { "libelle": "Carrefour Avedji", "lat": 6.169, "lng": 1.184 } ],
  "depart_le": "2026-10-08T07:30:00Z",
  "places_total": 2
}
```

→ 201 `trajet_conducteur`. Erreurs 400 par champ : `points_prise_en_charge` (1 à 3, dans l'ordre du trajet), `places_total` (1 à `nb_places − 1` du véhicule), `depart_le` (dans le futur).

## Objet `trajet_conducteur`

```json
{
  "id": 9001,
  "depart": { "…": "lieu" }, "arrivee": { "…": "lieu" },
  "points_prise_en_charge": [ { "id": 1, "ordre": 1, "libelle": "Carrefour Avedji", "lat": 6.169, "lng": 1.184 } ],
  "depart_le": "2026-10-08T07:30:00Z",
  "places_total": 2,
  "places_restantes": 1,
  "prix_place": 300,
  "statut": "publie",
  "economie": 0,
  "demandes": [ "…demande_conducteur" ],
  "actions": ["annuler"]
}
```

- `statut` : `publie` → `complet` (`places_restantes` = 0) → `en_cours` → `termine` | `annule`.
- `economie` : somme payée par les passagers de ce trajet (F CFA), calculée par le backend.
- `actions` du trajet : `annuler` (avant le départ), `terminer` (dès qu'un passager est `en_cours`).

## Objet `demande_conducteur` (réservation vue par le conducteur)

```json
{
  "id": 777,
  "passager": { "id": 31, "prenom": "Afi", "nom": "Amégan", "photo": null, "verifie": true, "note": 4.8 },
  "nb_places": 1,
  "point_prise_en_charge_id": 1,
  "statut": "acceptee",
  "methode_paiement": "flooz",
  "statut_paiement": "reussi",
  "montant": 300,
  "actions": ["saisir_code", "declarer_absence"]
}
```

- **Jamais de `code_depart`** dans cet objet : le conducteur ne fait que **saisir** le code donné par le passager.
- `actions` : `accepter`, `refuser` (en `demandee`) ; `saisir_code` (en `acceptee`) ; `declarer_absence` (en `acceptee`, à partir de `depart_le + tolerance_retard_min`).

## Endpoints

| Méthode | Chemin | Corps | Réponse | Erreurs |
|---|---|---|---|---|
| GET | `/trajets/mes-trajets/` | — | `[trajet_conducteur]` (prochains d'abord) | — |
| GET | `/trajets/{id}/conducteur/` | — | `trajet_conducteur` | 404 |
| POST | `/trajets/{id}/annuler/` | — | `trajet_conducteur` (`annule`, passagers notifiés et remboursés) | 409 |
| POST | `/trajets/{id}/terminer/` | — | `trajet_conducteur` (`termine` ; passagers `en_cours` → `terminee`) | 409 |
| POST | `/reservations/{id}/accepter/` | — | `demande_conducteur` (`acceptee`, place retirée, code généré) | 409 plus de place |
| POST | `/reservations/{id}/refuser/` | — | `demande_conducteur` (`refusee`) | 409 |
| POST | `/reservations/{id}/code/` | `code` (4 chiffres) | `demande_conducteur` (`en_cours`) | 400 `{"detail": "Code incorrect. 4 essais restants."}` · 429 trop d'essais |
| POST | `/reservations/{id}/absence/` | `lat`, `lng` (position du conducteur) | `demande_conducteur` (`absent`) | 409 trop tôt (avant départ + tolérance) |
| GET | `/conducteur/economies/` | `?mois=2026-10` (défaut : mois en cours) | `{ "mois": "2026-10", "total": 18500, "places": 24, "trajets": [ { "trajet_id", "date", "montant" } ] }` | — |

## Règles serveur

- Accepter : verrou `select_for_update` sur le trajet, `places_restantes −= nb_places`, code de départ généré (haché), notification au passager.
- Code : comparaison avec le hash, 5 essais maximum par réservation. La position du conducteur peut être enregistrée.
- Absence : position GPS du conducteur enregistrée avec la déclaration (preuve, PRD §11). Le passager paie le trajet et l'absence compte dans sa fiabilité.
- Terminer : trajet `termine`, réservations `en_cours` → `terminee` ; la clôture passe à `cloturee` sur confirmation du passager ou au bout de `delai_confirmation_auto_h` (S6).

## Mode mock

- Compte conducteur de démo : `conducteur@kovoit.tg` / `kovoit123` (KYC validés, véhicule Toyota Yaris, mode conducteur, 18 500 F d'économies ce mois).
- À la publication, deux passagers fictifs envoient automatiquement une demande.
- Code de départ accepté pour les demandes fictives : `4821`.
