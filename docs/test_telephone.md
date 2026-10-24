# Tester Kovoit sur un vrai téléphone

Les tests automatiques (`flutter test`) couvrent les écrans et les règles. Ce qui suit ne se
vérifie que sur un appareil réel : appareil photo, GPS, partage de position en arrière-plan,
liens externes, notifications push.

## 1. Installer l'application

### APK de démo (sans serveur)

Données simulées, aucun argent réel. Idéal pour tester les écrans, l'appareil photo et le GPS.

```bash
flutter build apk --release --dart-define=ENV=dev --dart-define=USE_MOCK_API=true
```

APK produit : `build/app/outputs/flutter-apk/app-release.apk`. L'envoyer sur le téléphone
(WhatsApp, câble USB, Google Drive) puis l'ouvrir ; Android demande d'autoriser l'installation
depuis cette source.

Connexion de démo : `demo@kovoit.tg` (passager) ou `conducteur@kovoit.tg` (conducteur), code `123456`.

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

Les codes de connexion arrivent par email (en local : affichés dans les logs du backend).

## 2. Liste de vérifications

Noter pour chaque ligne : ✅ OK, ❌ problème (avec une capture d'écran), et le modèle de
téléphone et la version d'Android.

### Compte
- [ ] Connexion par code email ; profil à compléter ; case CGU obligatoire ; le lien « Lire les
      conditions » ouvre le navigateur.
- [ ] Profil → Supprimer mon compte : refus expliqué si une réservation est en cours.

### Passager
- [ ] Recherche : saisie d'un lieu (ex. « univ »), choix sur la carte, bouton « ma position ».
- [ ] Vérification d'identité : photo de la pièce (appareil photo et galerie), selfie (caméra avant).
- [ ] Détail d'un trajet : prix par place, places restantes, total, mention « prix figé ».
- [ ] Réservation payée par le portefeuille ; recharge Flooz / Mixx (simulée en démo).
- [ ] Code de départ affiché après acceptation ; « Partager mon trajet » ouvre le partage.
- [ ] Notifications : Profil → Notifications ; toucher une notification ouvre la réservation.

### Conducteur
- [ ] Véhicule : consommation facultative (refus au-delà de 30 L/100 km).
- [ ] Publication : le détail du prix s'affiche dès le départ et la destination choisis.
- [ ] Accepter une demande, saisir le code de départ, déclarer une absence (position GPS demandée).
- [ ] **Partage de position en arrière-plan** : après avoir accepté un passager, quitter l'écran du
      trajet puis l'application. Vérifier la notification Android « Kovoit partage votre position ».
      Sur le lien partagé (page de suivi), la position doit se mettre à jour toutes les 30 s
      environ. Après « Terminer le trajet », la notification disparaît.
- [ ] Terminer le trajet ; noter un passager (y compris un passager absent).

### Général
- [ ] Mode sombre, petite et grande taille de police, rotation de l'écran.
- [ ] Coupure du réseau : messages d'erreur clairs, aucun montant inventé.
