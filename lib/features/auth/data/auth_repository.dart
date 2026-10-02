import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// `GoogleSignIn.initialize` may only be called once per process; every
/// user of Google Sign-In goes through here.
abstract final class GoogleSignInBootstrap {
  static Future<void>? _ready;

  static Future<void> ensureInitialized() =>
      _ready ??= GoogleSignIn.instance.initialize();

  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
}

enum GoogleLinkResult {
  /// Signed in (or the guest account was upgraded in place, keeping data).
  linked,

  /// The Google account already has data; the user must confirm switching,
  /// which leaves the guest data behind.
  accountExists,
  cancelled,
  unsupported,
}

/// Identity for data isolation. Every user has a Firebase UID: either a
/// Google account or an anonymous "guest" account created on first launch,
/// which can later be upgraded to Google without losing data.
class AuthRepository {
  AuthRepository({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  // Kept between [linkGoogle] and [switchToExistingGoogleAccount].
  AuthCredential? _pendingCredential;

  User? get currentUser => _auth.currentUser;

  Future<void> continueAsGuest() async {
    if (_auth.currentUser != null) return;
    await _auth.signInAnonymously();
  }

  /// Signs in with Google. A guest is upgraded in place (same UID, data
  /// kept). Requests only basic profile scopes.
  Future<GoogleLinkResult> linkGoogle() async {
    if (!GoogleSignInBootstrap.isSupported) return GoogleLinkResult.unsupported;
    await GoogleSignInBootstrap.ensureInitialized();
    final GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return GoogleLinkResult.cancelled;
      }
      rethrow;
    }
    final idToken = account.authentication.idToken;
    if (idToken == null) return GoogleLinkResult.cancelled;
    final credential = GoogleAuthProvider.credential(idToken: idToken);

    final user = _auth.currentUser;
    if (user == null || !user.isAnonymous) {
      await _auth.signInWithCredential(credential);
      return GoogleLinkResult.linked;
    }
    try {
      await user.linkWithCredential(credential);
      await user.reload();
      return GoogleLinkResult.linked;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use' ||
          e.code == 'email-already-in-use') {
        _pendingCredential = e.credential ?? credential;
        return GoogleLinkResult.accountExists;
      }
      rethrow;
    }
  }

  /// Completes [GoogleLinkResult.accountExists] after the user confirmed.
  Future<void> switchToExistingGoogleAccount() async {
    final credential = _pendingCredential;
    if (credential == null) return;
    _pendingCredential = null;
    await _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    if (GoogleSignInBootstrap.isSupported) {
      await GoogleSignInBootstrap.ensureInitialized();
      await GoogleSignIn.instance.signOut();
    }
    await _auth.signOut();
  }
}
