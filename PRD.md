# PRD — Kovoit Mobile (MVP)

> Sources : `docs/Kovoit Spécification du MVP (1).docx`, `docs/Nana Tech.zip` (11 maquettes Figma). Méthode de dev : [claude.md](claude.md). Agents : [agents.md](agents.md).

## 1. Problème & vision

Les passagers ont du mal à trouver rapidement un conducteur fiable qui fait déjà leur trajet. Les conducteurs n'ont pas de moyen simple de proposer leurs trajets et de gérer les demandes.

Kovoit met en relation des conducteurs qui se déplacent déjà dans **Lomé** avec des passagers qui vont dans la même direction. Le conducteur réduit ses frais de carburant, le passager paie moins cher qu'un zémidjan ou un taxi.

**Principes :**
- Trajets **urbains à Lomé uniquement**.
- **Partage de frais, pas de profit** : Kovoit n'est pas un service de taxi.
- **Prix fixe et connu à l'avance**, sans négociation.
- **Un seul compte, deux modes** : passager et conducteur.
- **KYC obligatoire** avant de réserver ou de publier.

## 2. Utilisateurs

| Rôle | Ce qu'il fait | Où |
|---|---|---|
| Passager | Recherche un trajet, consulte les conducteurs, réserve une place, donne le code de départ, confirme l'arrivée, note | App mobile |
| Conducteur | Déclare son véhicule, publie un trajet, accepte/refuse, saisit le code, clôture, note, suit ses économies | App mobile (mode conducteur) |
| Administrateur | Valide les KYC, consulte trajets/réservations/utilisateurs, traite les signalements et litiges, suspend, modifie les paramètres | Back-office React (hors de ce dépôt) |

Le mode conducteur s'active une fois le **KYC conducteur validé** et un **véhicule déclaré**.

## 3. Fonctionnalités du MVP (mobile)

**Passager**
- Créer un compte et vérifier son téléphone (OTP SMS)
- Soumettre son KYC passager
- Chercher un trajet : départ, arrivée, date, heure (type Moto/Voiture, nombre de places)
- Voir le profil du conducteur : statut vérifié, note, taux de fiabilité, véhicule, photo, immatriculation
- Demander une place, recevoir l'acceptation ou le refus (notification)
- Donner le code de départ au conducteur à la prise en charge
- Confirmer l'arrivée, noter le conducteur
- Partager son trajet en cours avec un proche
- Signaler un problème

**Conducteur** (en plus) :
- Soumettre son KYC conducteur, déclarer son véhicule (type, marque, modèle, couleur, immatriculation, nombre de places, photo)
- Publier un trajet : départ, arrivée, 1 à 3 points de prise en charge, date, heure, places
- Voir le prix par place (fourni par l'API)
- Accepter ou refuser les demandes
- Saisir le code de départ de chaque passager, déclarer une absence
- Clôturer le trajet, noter ses passagers
- Voir ses économies par trajet et le cumul du mois

## 4. Parcours principaux

**Conducteur :** créer son compte → vérifier son téléphone → KYC conducteur → déclarer son véhicule → saisir départ, destination, points de prise en charge, date, heure, places → publier → recevoir une demande → accepter/refuser → saisir le code de départ → transporter → clôturer → noter.

**Passager :** créer son compte → vérifier son téléphone → KYC passager → saisir départ, destination, date, heure → rechercher → consulter les conducteurs → choisir → demander une place → recevoir l'acceptation → rejoindre le point de prise en charge → donner le code → confirmer l'arrivée → noter.

## 5. Critères d'acceptation

**CA1 — Recherche.** Étant donné un trajet publié, quand le passager renseigne départ, destination, date et heure, alors l'application affiche les trajets correspondants avec : conducteur, photo, statut vérifié, note, véhicule, heure de départ, places restantes, distance de marche, prix par place, informations du trajet. Les résultats sont triés par heure de départ la plus proche, puis par distance de marche (tri fait par l'API).

**CA2 — Réservation.** Étant donné un trajet avec au moins une place et un passager au KYC `verifie`, quand il demande une place, alors une réservation `demandee` est créée et le conducteur est notifié. La place n'est retirée qu'à l'acceptation.

**CA3 — Acceptation.** Quand le conducteur accepte : la réservation passe à `acceptee`, une place est retirée, le passager est notifié et un **code de départ à 4 chiffres** est généré et affiché **uniquement au passager**.

**CA4 — Refus.** Quand le conducteur refuse une demande `demandee`, elle passe à `refusee` et le passager est informé.

**CA5 — Annulation.** Le passager ou le conducteur peut annuler une réservation `demandee` ou `acceptee` jusqu'au départ. L'autre partie est notifiée. La place est rendue. Une annulation à moins de `delai_annulation_min` du départ compte comme **annulation tardive** (affichée par l'API).

**CA6 — Vérification.** Sans KYC passager `verifie`, le bouton « Réserver » est bloqué avec un renvoi vers le KYC. Sans KYC conducteur `verifie` et véhicule déclaré, la publication est bloquée. Un compte suspendu ne peut ni réserver ni publier.

**CA7 — Prise en charge.** La réservation passe à `en_cours` **uniquement** quand le conducteur saisit le bon code. Un code faux affiche une erreur sans changer le statut.

**CA8 — Fin de trajet.** Après `terminee`, le passager peut confirmer (→ `cloturee`) ou signaler un problème (→ `litige`). Sans action, la clôture est automatique après `delai_confirmation_auto_h`. Les deux parties peuvent noter (1 à 5 ★ + commentaire optionnel).

**CA9 — Absence.** Après l'heure de départ + `tolerance_retard_min`, le conducteur peut déclarer un passager `absent` depuis le point de prise en charge. Sa position GPS est envoyée.

## 6. Écrans du MVP (maquettes Figma)

| # | Écran Figma | Feature | Contenu clé |
|---|---|---|---|
| 1 | Splash | auth | Logo, slogan « Même trajet, moins cher », barre de chargement |
| 2 | Connexion | auth | Onglets Connexion/Inscription, identifiants, mot de passe oublié, Google* |
| 3 | Inscription | auth | Nom complet, email, téléphone +228, mot de passe, CGU, Google* |
| 4 | Vérification SMS | auth | OTP 6 chiffres, numéro affiché, modifier le numéro, renvoi après 30 s |
| 5 | Vérification d'identité | kyc | 4 étapes : photo de profil, pièce recto, pièce verso, selfie ; progression |
| 6 | Profil vérifié | kyc | Récapitulatif des pièces complétées, bouton Continuer |
| 7 | Rechercher un trajet | search | Toggle Moto/Voiture, départ, destination, date, heure, places, trajet du quotidien |
| 8 | Conducteurs disponibles | search | Carte OSM, nombre de résultats, cartes conducteur (photo, badge vérifié, note, véhicule, places, départ, distance, prix) |
| 9 | Détails & Réservation | trip / booking | Prise en charge et arrivée estimée, conducteur (note, fiabilité, nb trajets), photo et immatriculation du véhicule, récapitulatif du prix, mode de paiement*, « Réserver ma place » |
| 10 | Suivi du trajet & Code de départ | booking | Carte, arrivée du conducteur, **code de départ**, Appeler, Message*, Partager mon trajet, Annuler |
| 11 | Espace Conducteur | driver | Toggle Passager/Conducteur, économies du mois, formulaire de publication (1–3 carrefours), places, prix recommandé |

\* Éléments soumis à une décision en attente (§14).

**Écrans à concevoir (absents de Figma) :** Mes trajets (liste passager/conducteur), Demandes reçues (Accepter/Refuser), Saisie du code de départ (conducteur), Déclaration du véhicule, Confirmation d'arrivée + Notation, Signalement, Profil.

**Navigation :** barre du bas **Rechercher / Mes trajets / Profil**.

## 7. Statuts

**Réservation (9) :** `demandee`, `acceptee`, `refusee`, `annulee`, `absent`, `en_cours`, `terminee`, `litige`, `cloturee`.

```
demandee → acceptee → en_cours → terminee → cloturee
demandee → refusee | annulee
acceptee → annulee | absent
terminee → litige → cloturee
```

**Trajet :** `publie`, `complet` (places_restantes = 0), `en_cours`, `termine` (toutes les réservations actives terminées), `annule`.

**KYC :** `non_verifie` → `en_attente` → `verifie` | `rejete` (motif, nouvelle soumission possible).

**Compte :** `actif` | `suspendu` (`suspendu_jusqu_au`).

Chaque changement de statut notifie l'autre partie (push, ou SMS si l'application est fermée).

## 8. Données (vues par le mobile)

| Entité | Champs principaux |
|---|---|
| User | id, telephone, nom, prenom, email, photo, mode_actif (passager/conducteur), statut_compte, suspendu_jusqu_au, note, fiabilite, nb_trajets |
| KycDossier | id, type (passager/conducteur), statut, motif_rejet, pièces (identite, selfie, permis, carte_grise, assurance, photo_vehicule) |
| Vehicle | id, type (moto/voiture), marque, modele, couleur, immatriculation, nb_places, photo, statut_verification |
| Trip | id, conducteur, vehicule, depart (lat, lng, libelle), arrivee (lat, lng, libelle), points_prise_en_charge[1..3], depart_le, places_total, places_restantes, distance_km, prix_place, statut |
| Booking | id, trajet, passager, point_prise_en_charge, nb_places, prix, frais_service, statut, code_depart (**visible passager uniquement**), horodatages |
| Rating | reservation, auteur, cible, note 1–5, commentaire |
| Report | reservation, auteur, cible, motif, statut (ouvert/traite) |
| Payment / Transaction | Conservé côté backend pour la suite, hors MVP mobile |

## 9. Recherche & localisation

- Départ/arrivée : coordonnées GPS + libellé (quartier, repère connu), choisis sur une carte **OpenStreetMap** (`flutter_map`) ou parmi des lieux connus.
- Points de prise en charge : 1 à 3 repères (carrefour, rond-point, station).
- Correspondance **calculée par le backend** : départ du passager ≤ `rayon_depart_km` d'un point de prise en charge, arrivée ≤ `rayon_arrivee_km`, écart horaire ≤ `fenetre_horaire_min`, au moins 1 place.
- Le mobile n'effectue aucun calcul de distance ni de correspondance.

## 10. Paramètres administrateur (lecture seule pour le mobile)

| Clé | Valeur de départ | Rôle |
|---|---|---|
| prix_litre | 817 F | Coût carburant |
| conso_l_100km | 7,5 | Coût carburant |
| grille_prix | <5 km : 200 F · 5–10 km : 300 F · >10 km : 500 F | Prix par passager (en attente, §14) |
| frais_service | 0 F | Désactivé pendant le pilote (en attente, §14) |
| rayon_depart_km / rayon_arrivee_km | 1,5 | Correspondance |
| fenetre_horaire_min | 15 | Correspondance |
| delai_annulation_min | 30 | Annulation tardive |
| tolerance_retard_min | 10 | Déclaration d'absence |
| delai_confirmation_auto_h | 3 | Clôture automatique |
| seuil_incidents | 3 sur 30 jours | Suspension |
| duree_suspension_j | 7 | Suspension |

## 11. Annulations & fiabilité

| Situation | Conséquence |
|---|---|
| Passager annule > 30 min avant | Gratuit |
| Passager annule < 30 min avant | Gratuit, compte comme annulation tardive |
| Passager absent (code jamais saisi) | Paie le trajet, compte comme absence |
| Conducteur annule | Passagers informés ; annulation tardive si < 30 min |
| Litige après le trajet | L'administrateur tranche |

Le taux de fiabilité (`1 − (annulations tardives + absences) / réservations sur 30 jours`) est **calculé par le backend** et affiché en % sur le profil. Au-delà de `seuil_incidents`, le compte est suspendu `duree_suspension_j` jours.

## 12. Paiement

MVP : **espèces**. Le passager paie le conducteur à la prise en charge. L'application enregistre le montant dû pour calculer les économies du conducteur.

Plus tard : portefeuille Kovoit rechargé par T-Money/Flooz via un agrégateur agréé, remboursements automatiques.

## 13. Sécurité & confiance

- Profil vérifié (badge), photo du conducteur, photo et immatriculation du véhicule visibles avant la prise en charge.
- **Code de départ à 4 chiffres** par réservation, stocké haché côté backend, jamais affiché au conducteur. Ne pas le confondre avec l'OTP SMS à 6 chiffres.
- « Partager mon trajet » : lien public temporaire avec la position du véhicule, valable jusqu'à la clôture.
- « Signaler un problème » pendant et après le trajet.
- Notes des deux côtés après chaque trajet.
- Pièces KYC : stockage privé côté backend, aucune copie persistante sur le téléphone.

## 14. Décisions en attente

Contradictions relevées entre la spécification, l'ancien PRD et les maquettes. **À trancher par l'équipe ; ne rien implémenter qui présuppose une réponse.**

| # | Sujet | Options |
|---|---|---|
| D1 | Calcul du prix | Grille 200/300/500 F par distance (spéc.) · pas de calcul dans le MVP (ancien PRD) · formule au km (ancien claude.md). Les maquettes affichent un « prix recommandé calculé automatiquement ». Quelle que soit l'option, le mobile **affiche** le prix de l'API. |
| D2 | Frais de service | 0 F pendant le pilote (spéc., maquettes « 0 FCFA ») · 10 % · frais fixes 50 F |
| D3 | Authentification | ✅ **Tranché (08/10/2026)** : e-mail + mot de passe **ou** Google, puis vérification du téléphone par OTP SMS (6 chiffres). Contrat : `docs/api/auth.md` |
| D4 | Bouton « Message » (écran 10) | Hors MVP (messagerie) : masquer, désactiver ou remplacer par SMS natif ? |
| D5 | Paiement « Mobile Money » (écran 9) | Hors MVP : masquer ou afficher « bientôt » ? |
| D6 | Backend | DRF seul · DRF + FastAPI |
| D7 | Paiement MVP | Espèces uniquement ou portefeuille dès le départ ? |

**Questions ouvertes (spécification) :** cadre légal du covoiturage avec partage de frais au Togo, agrégateur de paiement et frais réels, relevé terrain pour valider la grille de prix.

## 15. Hors périmètre du MVP

Messagerie intégrée · paiement Mobile Money / portefeuille · KYC automatique (OCR, comparaison du selfie) · passagers pris n'importe où sur l'itinéraire · trajets réguliers/récurrents · trajets interurbains · IA et recommandation · optimisation d'itinéraires · assurance intégrée · abonnement conducteur ou entreprises · statistiques avancées.

## 16. Stack

| Partie | Technologie |
|---|---|
| Application mobile | Flutter, Riverpod, go_router, Dio, freezed |
| Cartographie | OpenStreetMap (`flutter_map`) ; distances par la route via OSRM côté backend |
| Backend | Django / Django REST Framework (voir D6) |
| Base de données | PostgreSQL + PostGIS |
| Authentification | E-mail/mot de passe ou Google, JWT, OTP SMS (D3) |
| Notifications | Firebase Cloud Messaging (push) + SMS de repli |
| Administration | React |

## 17. Plan de livraison

| Sprint | Contenu |
|---|---|
| S0 Socle | Projet Flutter, arborescence, thème Figma, widgets communs, Dio, router, environnements, mocks API |
| S1 Auth | Splash, inscription, connexion, OTP SMS, tokens |
| S2 KYC + Véhicule | Parcours KYC 4 étapes, statut du dossier, déclaration du véhicule |
| S3 Recherche | Formulaire, résultats, carte OSM, profil conducteur |
| S4 Réservation passager | Détails, demande, statuts, code de départ, annulation, partage du trajet |
| S5 Conducteur | Bascule de mode, publication (1–3 points), demandes, saisie du code, absence, clôture, économies |
| S6 Après trajet | Confirmation, notation, signalement, notifications push |
| S7 Qualité | Tests CA1–CA9, erreurs et hors-ligne, accessibilité, APK de démo |

## Résumé

Conducteur vérifié → publie son trajet → passager recherche → consulte les conducteurs → demande une place → conducteur accepte → code de départ généré → prise en charge avec le code → trajet terminé → confirmation et notation.

Le mobile **affiche et déclenche**, le backend **calcule et décide**.
