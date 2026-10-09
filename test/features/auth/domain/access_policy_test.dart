import 'package:flutter_test/flutter_test.dart';
import 'package:kovoit/features/auth/domain/access_policy.dart';
import 'package:kovoit/features/auth/domain/entities/app_user.dart';

AppUser _user({
  KycStatus passager = KycStatus.nonVerifie,
  KycStatus conducteur = KycStatus.nonVerifie,
  bool vehicule = false,
  AccountStatus statut = AccountStatus.actif,
}) =>
    AppUser(
      id: 1,
      prenom: 'Afi',
      nom: 'Amégan',
      email: 'afi@exemple.com',
      telephone: '+22891234567',
      telephoneVerifie: true,
      kycPassager: passager,
      kycConducteur: conducteur,
      vehiculeDeclare: vehicule,
      statutCompte: statut,
    );

void main() {
  group('canBook (CA6 : KYC passager → réservation)', () {
    test('refusé tant que le KYC passager n’est pas vérifié', () {
      expect(AccessPolicy.canBook(_user()), AccessDenial.kycPassagerMissing);
      expect(AccessPolicy.canBook(_user(passager: KycStatus.enAttente)), AccessDenial.kycPassagerPending);
      expect(AccessPolicy.canBook(_user(passager: KycStatus.rejete)), AccessDenial.kycPassagerRejected);
    });

    test('autorisé avec un KYC passager vérifié', () {
      expect(AccessPolicy.canBook(_user(passager: KycStatus.verifie)), isNull);
    });

    test('compte suspendu : refusé quel que soit le KYC', () {
      expect(
        AccessPolicy.canBook(_user(passager: KycStatus.verifie, statut: AccountStatus.suspendu)),
        AccessDenial.suspended,
      );
    });
  });

  group('canSwitchToDriver (CA6 : KYC conducteur + véhicule → publication)', () {
    test('renvoie la première étape manquante, dans l’ordre', () {
      expect(AccessPolicy.canSwitchToDriver(_user()), AccessDenial.kycPassagerMissing);
      expect(AccessPolicy.canSwitchToDriver(_user(passager: KycStatus.verifie)), AccessDenial.kycConducteurMissing);
      expect(
        AccessPolicy.canSwitchToDriver(_user(passager: KycStatus.verifie, conducteur: KycStatus.enAttente)),
        AccessDenial.kycConducteurPending,
      );
      expect(
        AccessPolicy.canSwitchToDriver(_user(passager: KycStatus.verifie, conducteur: KycStatus.verifie)),
        AccessDenial.vehicleMissing,
      );
    });

    test('autorisé quand tout est validé', () {
      final ready = _user(passager: KycStatus.verifie, conducteur: KycStatus.verifie, vehicule: true);
      expect(AccessPolicy.canSwitchToDriver(ready), isNull);
      expect(AccessPolicy.canPublish(ready), isNull);
    });
  });

  test('macaron orange : uniquement quand une action KYC est attendue', () {
    expect(AccessPolicy.needsKycAttention(_user()), isTrue);
    expect(AccessPolicy.needsKycAttention(_user(passager: KycStatus.rejete)), isTrue);
    expect(AccessPolicy.needsKycAttention(_user(passager: KycStatus.enAttente)), isFalse);
    expect(AccessPolicy.needsKycAttention(_user(passager: KycStatus.verifie)), isFalse);
  });

  test('le dossier conducteur suppose le dossier passager envoyé', () {
    expect(AccessPolicy.canStartDriverKyc(_user()), isFalse);
    expect(AccessPolicy.canStartDriverKyc(_user(passager: KycStatus.enAttente)), isTrue);
  });
}
