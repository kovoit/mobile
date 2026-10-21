# Contrat API — Authentification et profil (backend `kovoit/backend`, app `accounts`)

Base : `/api/v1`. Réponses enveloppées : `{"statut": "success" | "failed", "message", "reponse"}`.
Erreur : `reponse = {"code", "erreurs"}`. Jetons JWT (simplejwt) : access 15 min, refresh 7 jours, rotation + liste noire.

**Décision D3 (révisée le 10/10/2026)** : connexion **sans mot de passe**, par un **code à 6 chiffres envoyé par e-mail**.
Le compte est créé au premier code valide. Plus de mot de passe, de Google ni d'OTP SMS.

## Parcours mobile

1. `/connexion` : saisie de l'e-mail → `POST /auth/otp/demander/`.
2. `/connexion/code` : saisie du code → `POST /auth/otp/verifier/` (jetons stockés dans `flutter_secure_storage`).
3. `/completer-profil` si `profil_complet = false` : prénom, nom, téléphone → `PATCH /moi/`.
4. Application. Le KYC se fait ensuite depuis le Profil (non bloquant, retour UX du 08/10).

## Objet `profil` (`ProfilSerializer`)

```json
{
  "id": "3f1c2b9e-…", "email": "kodjo@exemple.com", "telephone": "+22890123456",
  "nom": "Mensah", "prenom": "Kodjo", "photo": null, "email_verifie": true,
  "mode_actif": "passager", "statut_compte": "actif", "suspendu_jusqu_au": null,
  "profil_complet": true,
  "kyc": { "passager": "verifie", "conducteur": "non_verifie" },
  "etat": {
    "badge_kyc": false,
    "acces": { "peut_rechercher": true, "peut_reserver": true, "peut_publier": false },
    "mode_conducteur": { "disponible": false, "kyc_conducteur_verifie": false, "vehicule_declare": false },
    "alertes": [ { "code": "KYC_CONDUCTEUR_NON_VERIFIE", "message": "…", "action_requise": false } ]
  }
}
```

Mapping mobile : `ProfilDto` → `AppUser` (`features/auth/data/dto/profil_dto.dart`).

## Endpoints

| Méthode | Chemin | Corps | Réponse | Erreurs |
|---|---|---|---|---|
| POST | `/auth/otp/demander/` | `email` | message seul | 429 `TROP_DE_REQUETES` (délai de 60 s entre deux envois, 5 par heure) |
| POST | `/auth/otp/verifier/` | `email`, `code` (6 chiffres) | `{utilisateur, nouveau_compte, access, refresh}` | 400 `CODE_OTP_INVALIDE` (valable 10 min, 5 essais) · compte désactivé |
| POST | `/auth/jeton/rafraichir/` | `refresh` | `{access, refresh}` (nouveau refresh) | 401 `SESSION_EXPIREE` |
| POST | `/auth/deconnexion/` | `refresh` | message seul | — |
| GET | `/moi/` | — | `profil` | 401 |
| PATCH | `/moi/` | `prenom`, `nom`, `telephone`, `photo` (multipart) | `profil` | 400 par champ |
| PATCH | `/moi/mode/` | `mode_actif` | `profil` | 403 `KYC_CONDUCTEUR_REQUIS`, `VEHICULE_REQUIS` |

- Le code de connexion (6 chiffres) est **distinct** du code de départ (4 chiffres) des réservations.
- Le délai de renvoi (60 s, paramètre `otp_delai_renvoi_s`) n'est pas renvoyé par l'API : le mobile l'applique (`AuthRepositoryImpl.resendDelay`).

## Mode mock (application)

`USE_MOCK_API` (activé par défaut en `dev`) :

- `demo@kovoit.tg` (passager, KYC passager validé) et `conducteur@kovoit.tg` (conducteur) ;
- code accepté : `123456` ;
- toute autre adresse crée un compte neuf, qui passe par la complétion du profil.
