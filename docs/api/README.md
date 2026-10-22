# Contrat API de l'application mobile

**Source de vérité : le backend.** Schéma OpenAPI complet sur `/api/docs/` (Swagger) du backend
Django, et réponses réelles enregistrées dans `test/fixtures/backend/` (test de contrat
`test/core/network/api_contract_test.dart`). Ce fichier résume ce que l'app utilise.

Base : `/api/v1`. Toutes les réponses : `{ "statut": "success" | "failed", "message", "reponse" }`.
En échec : `reponse = { "code": "<CODE_METIER>", "erreurs": … }`. Identifiants : UUID (chaînes).
Listes paginées : `reponse = { count, next, previous, results }` (`?page=`, `?taille=`).

## Décisions qui façonnent le contrat (22/10/2026)

- **Paiement : portefeuille + PayGate (Flooz, Mixx), pas d'espèces.** Le montant est bloqué à la
  demande de place et débité à la prise en charge. S'il manque de l'argent, le passager recharge
  d'abord (`recharge_suggeree`), puis réserve.
- **Une réservation = une place.** Pas de filtre moto / voiture dans la recherche.
- **Pas de liste de notifications dans l'app** : le backend envoie push (et email de secours).
- Itinéraire tracé et heure d'arrivée estimée : non fournis par le backend, non affichés.

## Routes utilisées

| Domaine | Route | Notes |
|---|---|---|
| Auth | `POST auth/otp/demander/`, `POST auth/otp/verifier/`, `POST auth/jeton/rafraichir/`, `POST auth/deconnexion/` | |
| Profil | `GET/PATCH moi/`, `PATCH moi/mode/`, `GET moi/economies/` | économies : `mois_en_cours`, `total`, `par_trajet` |
| KYC | `GET kyc/`, `POST kyc/{type}/pieces/` (multipart), `POST kyc/{type}/soumettre/` | |
| Véhicule | `GET vehicules/` (premier), `POST vehicules/`, `PATCH vehicules/{id}/` | `type_vehicule`, `nb_places` |
| Lieux | `GET lieux/?q=` | 2 caractères minimum, sans accents, 20 au plus |
| Recherche | `GET trajets/recherche/?depart_lat&depart_lng&arrivee_lat&arrivee_lng&date_heure` | liste de `{trajet, point_propose, distance_marche_km, ecart_minutes}` |
| Trajet | `GET trajets/{id}/` | avec `paiement` : `montant_total`, `solde_disponible`, `complement_a_payer`, `recharge_suggeree` |
| Réservation | `POST reservations/` (`trajet_id`, `point_id`, `arrivee_lat`, `arrivee_lng`, `arrivee_libelle`), `GET reservations/`, `GET reservations/{id}/` | `code_depart` présent seulement pour le passager, réservation acceptée |
| | `POST reservations/{id}/annuler/`, `…/confirmer-arrivee/`, `…/partage/` (`{jeton, chemin}`) | |
| | `POST reservations/{id}/note/` (`note`, `commentaire`), `…/signalement/` (`motif`) | |
| Conducteur | `POST trajets/` (`vehicule_id`, `depart_*`, `arrivee_*`, `depart_le`, `places`, `points`), `GET trajets/mes-trajets/`, `GET trajets/{id}/reservations/` | prix fixé par Kovoit |
| | `POST trajets/{id}/annuler/`, `…/terminer/` ; `POST reservations/{id}/accepter/`, `…/refuser/`, `…/code-depart/` (`code`), `…/absent/` (`lat`, `lng`) | |
| Portefeuille | `GET portefeuille/`, `GET portefeuille/transactions/`, `GET portefeuille/transactions/{id}/` | une recharge en attente est revérifiée auprès de PayGate à chaque lecture |
| | `POST portefeuille/recharger/`, `…/retirer/` (`montant`, `moyen` = `flooz` \| `mixx`, `telephone`) | 201 validée, 202 en attente |
| Push | `POST notifications/appareils/` (`jeton`, `plateforme`), `DELETE notifications/appareils/{jeton}/` | |

## Actions proposées dans l'app

L'API ne renvoie pas de liste d'actions : l'app les déduit du statut (`BookingAction.forStatus`,
`DriverRequestAction.forStatus`, `DriverTripAction.forStatus`) et le backend refuse toute action
devenue impossible avec un message et un code affichés tels quels (`NON_ANNULABLE`,
`ABSENCE_PREMATUREE`, `DEJA_NOTE`, `PLUS_DE_PLACE`…).
