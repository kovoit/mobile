# Tester Kovoit sur un vrai téléphone

Les tests automatiques (`flutter test`) couvrent les écrans et les règles. Ce qui suit ne se
vérifie que sur un appareil réel : appareil photo, GPS, partage de position en arrière-plan,
liens externes, notifications push.

## 1. Installer l'application

### APK de démo (sans serveur)

Données simulées, aucun argent réel. Convient pour les écrans, l'appareil photo, le GPS et la
recherche. La démo ne joue jamais le conducteur ni le passager : un trajet publié reste sans
demande et une réservation reste « En attente ». Seule simulation conservée : Profil → « Mode
démo » → **Valider / Refuser les dossiers** (décision de l'administrateur KYC, sur clic). Les
vérifications marquées *(vrai backend)* demandent l'APK branché sur le vrai backend.

```bash
flutter build apk --release --dart-define=ENV=dev --dart-define=USE_MOCK_API=true
```

APK produit : `build/app/outputs/flutter-apk/app-release.apk`. L'envoyer sur le téléphone
(WhatsApp, câble USB, Google Drive) puis l'ouvrir ; Android demande d'autoriser l'installation
depuis cette source.

Connexion de démo par e-mail + mot de passe : `demo@kovoit.tg` (passager) ou
`conducteur@kovoit.tg` (conducteur). Le mot de passe est rappelé sur l'écran de connexion en démo
(`lib/core/config/demo_account.dart`). Le code `123456` sert seulement à vérifier l'e-mail et à
« Mot de passe oublié ».

### APK branché sur le vrai backend

1. Lancer le backend sur un ordinateur : `docker compose up` (dans `backend/`).
2. Le rendre joignable depuis le téléphone, au choix :
   - même Wi-Fi : adresse IP locale de l'ordinateur (ex. `http://192.168.1.20:8001/api/v1`) ;
   - autre réseau : un tunnel HTTPS (ex. `ngrok http 8001`) → `https://xxxx.ngrok-free.app/api/v1`.
3. Construire l'APK avec cette adresse :

```bash
flutter build apk --release --dart-define=ENV=dev --dart-define=USE_MOCK_API=false \
  --dart-define=API_BASE_URL=https://xxxx.ngrok-free.app/api/v1
```

Connexion par e-mail + mot de passe. Les codes de vérification de l'e-mail et de « Mot de passe
oublié » arrivent par e-mail (en local : affichés dans les logs du backend).

### Parcours complet : deux comptes, deux téléphones

Acceptation, code de départ, partage de position, fin du trajet et notation ne se testent que sur
le vrai backend : un compte conducteur sur un téléphone, un compte passager sur l'autre, l'app
construite ou lancée avec `--dart-define=USE_MOCK_API=false`, et le temps avancé sur le PC par
`python manage.py avancer_trajet`. Comptes de test et scénario pas à pas :
[backend/README.md](../../backend/README.md), section « Tester un trajet complet avec deux
téléphones ».

## 2. Liste de vérifications

Noter pour chaque ligne : ✅ OK, ❌ problème (avec une capture d'écran), et le modèle de
téléphone et la version d'Android.

### Compte
- [ ] Inscription (prénom, nom, e-mail, téléphone, mot de passe) ; case CGU obligatoire ; le lien
      « Lire les conditions » ouvre le navigateur ; code de vérification de l'e-mail.
- [ ] Connexion par e-mail + mot de passe ; « Mot de passe oublié » par code.
- [ ] Profil → Supprimer mon compte : refus expliqué si une réservation est en cours.

### Passager
- [ ] Recherche : saisie d'un lieu (ex. « univ »), choix sur la carte, bouton « ma position ».
- [ ] Vérification d'identité : photo de la pièce (appareil photo et galerie), selfie (caméra avant).
- [ ] Détail d'un trajet : prix par place, places restantes, total, mention « prix figé ».
- [ ] Réservation payée par le portefeuille ; recharge Flooz / Mixx (simulée en démo).
- [ ] *(vrai backend)* Code de départ affiché après acceptation par le conducteur ; « Partager mon
      trajet » ouvre le partage.
- [ ] Notifications : Profil → Notifications ; toucher une notification ouvre la réservation.

### Conducteur
- [ ] Véhicule : consommation facultative (refus au-delà de 30 L/100 km).
- [ ] Publication : le détail du prix s'affiche dès le départ et la destination choisis.
- [ ] *(vrai backend)* Accepter une demande, saisir le code de départ, déclarer une absence
      (position GPS demandée).
- [ ] *(vrai backend)* **Partage de position en arrière-plan** : après avoir accepté un passager,
      quitter l'écran du trajet puis l'application. Vérifier la notification Android « Kovoit partage votre position ».
      Sur le lien partagé (page de suivi), la position doit se mettre à jour toutes les 30 s
      environ. Après « Terminer le trajet », la notification disparaît.
- [ ] *(vrai backend)* Terminer le trajet ; noter un passager (y compris un passager absent).

### Général
- [ ] Mode sombre, petite et grande taille de police, rotation de l'écran.
- [ ] Coupure du réseau : messages d'erreur clairs, aucun montant inventé.
