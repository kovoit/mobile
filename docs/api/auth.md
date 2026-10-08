# Contrat API — Authentification (Sprint S1)

Contrat attendu par l'application mobile. Base : `/api/v1`. JSON, champs en `snake_case`.
Jetons : JWT (format `djangorestframework-simplejwt`). Header : `Authorization: Bearer <access>`.

Décision D3 (PRD §14) : **email + mot de passe, ou Google**, puis **vérification du téléphone par OTP SMS** (6 chiffres).

## Objet `user`

```json
{
  "id": 42,
  "prenom": "Kodjo",
  "nom": "Mensah",
  "email": "kodjo@exemple.com",
  "telephone": "+22890123456",
  "telephone_verifie": true,
  "photo": "https://.../photo.jpg",
  "mode_actif": "passager",
  "statut_compte": "actif",
  "suspendu_jusqu_au": null,
  "kyc_passager": "non_verifie",
  "kyc_conducteur": "non_verifie"
}
```

- `telephone` peut être `null` (compte créé via Google sans numéro).
- `mode_actif` : `passager` | `conducteur`.
- `statut_compte` : `actif` | `suspendu`.
- `kyc_*` : `non_verifie` | `en_attente` | `verifie` | `rejete`.

## Réponse d'authentification

Renvoyée par `register`, `login` et `google` :

```json
{ "access": "<jwt>", "refresh": "<jwt>", "user": { ... } }
```

## Endpoints

| Méthode | Chemin | Corps | Réponse | Erreurs |
|---|---|---|---|---|
| POST | `/auth/register/` | `nom_complet`, `email`, `telephone` (E.164 `+228…`), `password`, `cgu_acceptees` (true) | 201 + réponse d'auth | 400 avec erreurs par champ (`email`, `telephone`, `password`…) |
| POST | `/auth/login/` | `email`, `password` | 200 + réponse d'auth | 400/401 `{"detail": "Email ou mot de passe incorrect."}` |
| POST | `/auth/google/` | `id_token` (Google ID token) | 200 + réponse d'auth (compte créé si inexistant) | 400 jeton invalide |
| POST | `/auth/token/refresh/` | `refresh` | 200 `{"access", "refresh"?}` | 401 |
| POST | `/auth/logout/` | `refresh` | 205 (refresh mis en liste noire) | — |
| GET | `/auth/me/` | — | 200 `user` | 401 |
| PATCH | `/auth/me/telephone/` | `telephone` | 200 `user` (`telephone_verifie` repasse à false) | 400 numéro invalide ou déjà utilisé |
| POST | `/auth/otp/send/` | — (numéro du compte) | 200 `{"telephone", "expire_dans": 300, "renvoi_dans": 30}` | 429 `{"detail", "renvoi_dans"}` trop de demandes |
| POST | `/auth/otp/verify/` | `code` (6 chiffres) | 200 `user` (`telephone_verifie: true`) | 400 code invalide ou expiré |
| POST | `/auth/password/reset/` | `email` | 204 (toujours, même si l'email est inconnu) | — |

## Notes pour le backend

- `nom_complet` (champ unique de la maquette « Inscription ») est découpé côté serveur en `prenom` / `nom`.
- Le code OTP SMS (6 chiffres) est **distinct** du code de départ (4 chiffres) des réservations.
- L'OTP n'est envoyé que sur appel explicite à `/auth/otp/send/` (pas d'envoi automatique à l'inscription) pour éviter les doublons de SMS.
- `/auth/google/` vérifie l'`id_token` auprès de Google (audience = client OAuth « Web » du projet).

## Mode mock (application)

Tant que le backend n'est pas disponible, l'app tourne avec une fausse API en mémoire (`USE_MOCK_API`, activé par défaut en `dev`) :

- compte de démonstration : `demo@kovoit.tg` / `kovoit123` (téléphone vérifié) ;
- code OTP accepté : `123456`.
