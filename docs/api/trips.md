# Contrat API — Lieux, recherche et détail de trajet (Sprint S3)

Base : `/api/v1`. Authentification JWT requise, **téléphone vérifié** (la recherche ne demande pas le KYC).
Toute la correspondance (rayons, fenêtre horaire, tri), les distances et les prix sont **calculés par le backend**. Le mobile affiche ce qu'il reçoit.

## Objet `lieu`

```json
{ "id": 3, "libelle": "Carrefour Franciscain", "quartier": "Adidogomé", "type": "carrefour", "lat": 6.1660, "lng": 1.1650 }
```

`type` : `carrefour` | `quartier` | `repere` | `point_carte` (point choisi sur la carte, sans `id`).

## Objet `trajet_resume` (résultat de recherche)

```json
{
  "id": 41,
  "conducteur": {
    "id": 8, "prenom": "Koffi", "nom": "Mensah", "photo": "https://…",
    "verifie": true, "note": 4.9, "fiabilite": 98, "nb_trajets": 128
  },
  "vehicule": {
    "type": "voiture", "marque": "Toyota", "modele": "Yaris", "couleur": "Gris",
    "immatriculation": "TG 4827 AU", "photo": "https://…"
  },
  "depart": { "libelle": "Carrefour Franciscain", "quartier": "Adidogomé", "lat": 6.166, "lng": 1.165 },
  "arrivee": { "libelle": "Université de Lomé · Entrée sud", "quartier": "Tokoin", "lat": 6.168, "lng": 1.214 },
  "points_prise_en_charge": [
    { "id": 101, "ordre": 1, "libelle": "Carrefour Franciscain", "lat": 6.166, "lng": 1.165 },
    { "id": 102, "ordre": 2, "libelle": "Carrefour Avedji", "lat": 6.169, "lng": 1.184 }
  ],
  "point_correspondant_id": 101,
  "depart_le": "2026-10-08T07:30:00Z",
  "arrivee_estimee_le": "2026-10-08T07:55:00Z",
  "places_restantes": 2,
  "prix_place": 300,
  "frais_service": 0,
  "prix_total": 300,
  "distance_marche_km": 1.2
}
```

- `point_correspondant_id` : point de prise en charge le plus proche du départ du passager (fixé par le backend).
- `distance_marche_km` : distance entre le départ du passager et ce point.
- `prix_place`, `frais_service`, `prix_total` : F CFA entiers, **calculés par le backend** (décisions D1 / D2 en attente : le mobile affiche). `prix_total` correspond aux `places` demandées ; l'app ne le recalcule jamais.
- Dates en UTC ISO 8601. Lomé est à UTC+0 toute l'année.

## Endpoints

| Méthode | Chemin | Paramètres | Réponse | Erreurs |
|---|---|---|---|---|
| GET | `/lieux/` | `q` (≥ 2 caractères, optionnel) | 200 `[lieu]` (20 max, lieux connus de Lomé) | — |
| GET | `/trajets/recherche/` | `depart_lat`, `depart_lng`, `arrivee_lat`, `arrivee_lng`, `date_heure` (ISO UTC), `places` (≥ 1), `type_vehicule` (`moto` \| `voiture`) | 200 `{ "itineraire": {…}, "resultats": [trajet_resume] }` | 400 paramètres invalides |
| GET | `/trajets/{id}/` | `places` (optionnel, défaut 1) | 200 `trajet_resume` (sans `distance_marche_km` si appelé hors recherche) | 404 trajet introuvable ou plus disponible |

### `itineraire`

```json
{ "distance_km": 8.4, "duree_min": 25, "points": [[6.166, 1.165], [6.169, 1.184], [6.168, 1.214]] }
```

Itinéraire **par la route** du passager (OSRM côté backend), affiché sur la carte des résultats.

## Règles de correspondance (rappel, PRD §9)

- point de prise en charge à ≤ `rayon_depart_km` du départ du passager ;
- arrivée du conducteur à ≤ `rayon_arrivee_km` de l'arrivée du passager ;
- départ à ± `fenetre_horaire_min` de l'heure souhaitée ;
- `places_restantes` ≥ `places` demandées ; même type de véhicule ;
- tri : heure de départ la plus proche, puis distance de marche ;
- jamais les trajets de l'utilisateur lui-même, ni ceux d'un conducteur suspendu.

## Mode mock (application)

L'API simulée (`core/mock/fake_trips.dart`) contient des lieux connus de Lomé et des trajets quotidiens, par exemple Adidogomé → Université de Lomé en voiture à 07:30, 07:40 et 07:45, et en moto à 07:35. Elle applique ces règles avec des distances à vol d'oiseau, ce qui suffit pour une démo.
