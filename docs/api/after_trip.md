# Contrat API — Après le trajet et notifications (Sprint S6)

Base : `/api/v1`. JWT requis.

## Nouvelles actions sur une réservation

Le champ `actions` (voir [bookings.md](bookings.md) et [driver.md](driver.md)) s'enrichit :

| Action | Pour | Quand |
|---|---|---|
| `confirmer` | passager | réservation `terminee` |
| `noter` | passager et conducteur | `terminee`, `cloturee` ou `absent` (côté conducteur), une seule note par auteur |
| `signaler` | passager et conducteur | `en_cours`, `terminee`, `cloturee` (7 jours après), `absent` ; un signalement ouvert au plus par auteur |

## Endpoints

| Méthode | Chemin | Corps | Réponse | Erreurs |
|---|---|---|---|---|
| POST | `/reservations/{id}/confirmer/` | — | `reservation` (`cloturee` ; paiement mobile versé au conducteur) | 409 |
| POST | `/reservations/{id}/notes/` | `note` (1 à 5), `commentaire` (≤ 300 caractères, optionnel) | 201 `{ "note", "commentaire" }` | 400 · 409 déjà noté |
| POST | `/signalements/` | `reservation_id`, `motif`, `description` (≤ 1000 caractères) | 201 `{ "id", "statut": "ouvert" }` | 400 · 409 déjà signalé |
| GET | `/notifications/` | — | `[notification]` (récentes d'abord, 50 max) | — |
| POST | `/notifications/lues/` | `ids` (optionnel : toutes si absent) | 204 | — |
| POST | `/appareils/` | `token` (FCM), `plateforme` (`android` \| `ios`) | 204 | — |
| DELETE | `/appareils/{token}/` | — | 204 (déconnexion) | — |

- **L'auteur d'une note est déduit du JWT** : un même endpoint sert au passager (note du conducteur) et au conducteur (note du passager). La moyenne affichée sur les profils est recalculée par le serveur.
- **Motifs de signalement** : `retard`, `comportement`, `securite`, `vehicule`, `paiement`, `autre`.
- Un signalement sur une réservation `terminee` la fait passer en **`litige`** : le paiement mobile est gelé et l'administrateur tranche. Le serveur clôture la réservation (`cloturee`) quand le litige est résolu.
- **Clôture automatique** : sans confirmation ni signalement, une réservation `terminee` passe `cloturee` après `delai_confirmation_auto_h` (3 h). Tâche planifiée côté serveur.

## Objet `notification`

```json
{
  "id": 12,
  "type": "reservation_acceptee",
  "titre": "Koffi a accepté votre demande",
  "message": "Départ 07:30 · Carrefour Franciscain. Votre code de départ est disponible.",
  "cree_le": "2026-10-08T07:05:00Z",
  "lue": false,
  "cible": { "reservation_id": 501 }
}
```

| `type` | Destinataire | Cible |
|---|---|---|
| `nouvelle_demande` | conducteur | `trajet_id` |
| `reservation_acceptee`, `reservation_refusee`, `reservation_annulee` | passager / conducteur | `reservation_id` ou `trajet_id` |
| `prise_en_charge`, `trajet_termine` (« confirmez votre arrivée ») | passager | `reservation_id` |
| `paiement_reussi`, `paiement_echoue`, `remboursement` | passager | `reservation_id` |
| `kyc_valide`, `kyc_refuse` | utilisateur | — (Profil) |

Le message ne contient **jamais** le code de départ (une notification peut s'afficher sur l'écran verrouillé).

## Push (FCM)

- Chaque notification est aussi envoyée en push (FCM) aux appareils enregistrés, avec `data` = `{ "notification_id", "type", "reservation_id" | "trajet_id" }`. Si aucun appareil n'est actif ou si la livraison échoue, le serveur bascule en **SMS** (spéc. : « SMS si l'application est fermée »).
- Côté mobile, le push est désactivé tant que Firebase n'est pas configuré (`--dart-define=PUSH_ENABLED=true`, voir README). L'app relit alors `/notifications/` à l'ouverture, au retour au premier plan et toutes les 60 s.

## Mode mock

- Les actions simulées (le conducteur accepte, prend en charge, termine… ou le passager demande une place) créent les notifications correspondantes.
- Sur l'écran de suivi, le bloc « Mode démo » propose en plus **Terminer le trajet** pour tester la confirmation d'arrivée et la notation.
