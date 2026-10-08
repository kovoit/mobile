import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/repositories/auth_repository.dart';

/// Obtient un ID token Google à transmettre au backend (`/auth/google/`).
abstract interface class GoogleAuthService {
  /// `null` si l'utilisateur ferme la fenêtre Google.
  Future<String?> getIdToken();

  Future<void> signOut();
}

/// Implémentation `google_sign_in` 7.x.
/// Prérequis : client OAuth « Web » ([serverClientId]) + empreinte SHA-1 Android déclarée
/// dans Google Cloud (voir README).
class GoogleSignInAuthService implements GoogleAuthService {
  GoogleSignInAuthService({required this.serverClientId, GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final String serverClientId;
  final GoogleSignIn _googleSignIn;
  Future<void>? _initialization;

  Future<void> _ensureInitialized() =>
      _initialization ??= _googleSignIn.initialize(serverClientId: serverClientId);

  @override
  Future<String?> getIdToken() async {
    if (serverClientId.isEmpty) throw const GoogleSignInUnavailableException();
    await _ensureInitialized();
    if (!_googleSignIn.supportsAuthenticate()) throw const GoogleSignInUnavailableException();
    try {
      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) throw const GoogleSignInUnavailableException('Google n’a pas renvoyé d’identifiant.');
      return idToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      throw GoogleSignInUnavailableException('Connexion Google impossible (${e.code.name}).');
    }
  }

  @override
  Future<void> signOut() async {
    if (_initialization == null) return;
    await _googleSignIn.signOut();
  }
}

/// Mode mock : simule un compte Google sans configuration OAuth.
class FakeGoogleAuthService implements GoogleAuthService {
  @override
  Future<String?> getIdToken() async => 'mock-google-id-token';

  @override
  Future<void> signOut() async {}
}
