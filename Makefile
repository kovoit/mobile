# Makefile de l'application mobile Kovoit (Flutter) : raccourcis des commandes de claude.md §6.
#
# Quatre façons de lancer l'app :
# - `make lancer`      : backend en ligne (https://api.kovoittg.com), comme `flutter run`.
# - `make lancer-demo` : API simulée (FakeBackend), aucun backend requis.
#                        Démo : demo@kovoit.tg / kovoit123, OTP 123456.
# - `make lancer-usb`  : vrai backend, téléphone branché en USB (adb reverse : le port 8000 du
#                        téléphone est relié à celui du PC). Backend : `make serveur` dans backend/.
# - `make lancer-wifi` : vrai backend par le Wi-Fi. Backend : `make mobile` dans backend/.
#
# Choisir l'appareil : make lancer APPAREIL=988AY13F0A (liste : make appareils).

.DEFAULT_GOAL := aide
.PHONY: aide installer generer appareils lancer lancer-demo lancer-usb lancer-wifi analyser tests \
	tests-contrat apk nettoyer

PORT ?= 8000
APPAREIL ?=
CIBLE := $(if $(APPAREIL),-d $(APPAREIL),)
ADB ?= $(shell command -v adb 2>/dev/null || echo $(HOME)/Android/Sdk/platform-tools/adb)
IP_LOCALE := $(shell hostname -I 2>/dev/null | awk '{print $$1}')
VRAIE_API := --dart-define=USE_MOCK_API=false --dart-define=API_BASE_URL

aide: ## Liste les cibles disponibles
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*## "} {printf "  %-15s %s\n", $$1, $$2}'

installer: ## Installe les dépendances (flutter pub get)
	flutter pub get

generer: ## Régénère les DTO (build_runner), après toute modification d'un DTO
	dart run build_runner build --delete-conflicting-outputs

appareils: ## Liste les appareils et émulateurs détectés
	flutter devices

lancer: ## Lance l'app sur le backend en ligne (https://api.kovoittg.com)
	flutter run $(CIBLE)

lancer-demo: ## Lance l'app avec l'API simulée (aucun backend requis)
	flutter run $(CIBLE) --dart-define=USE_MOCK_API=true

lancer-usb: ## Lance l'app sur le vrai backend, téléphone en USB (adb reverse)
	$(ADB) $(if $(APPAREIL),-s $(APPAREIL),) reverse tcp:$(PORT) tcp:$(PORT)
	flutter run $(CIBLE) $(VRAIE_API)=http://127.0.0.1:$(PORT)/api/v1

lancer-wifi: ## Lance l'app sur le vrai backend par le Wi-Fi (IP du PC détectée)
	@echo "API : http://$(IP_LOCALE):$(PORT)/api/v1"
	flutter run $(CIBLE) $(VRAIE_API)=http://$(IP_LOCALE):$(PORT)/api/v1

analyser: ## Analyse statique (flutter analyze)
	flutter analyze

tests: ## Lance tous les tests (flutter test)
	flutter test

tests-contrat: ## Test de contrat : le FakeBackend produit le même JSON que le backend
	flutter test test/core/network/api_contract_test.dart

apk: ## Construit l'APK de production (ENV=prod)
	flutter build apk --dart-define=ENV=prod

nettoyer: ## Supprime les fichiers de build (flutter clean)
	flutter clean
