import 'package:firebase_auth/firebase_auth.dart' as fb;

/// Thin wrapper around package:firebase_auth — the only file in this module
/// allowed to import it directly.
class FirebaseAuthDatasource {
  final fb.FirebaseAuth _firebaseAuth;

  FirebaseAuthDatasource(this._firebaseAuth);

  Stream<fb.User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<fb.UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() => _firebaseAuth.signOut();

  Future<String?> getIdToken() =>
      _firebaseAuth.currentUser?.getIdToken() ?? Future.value(null);
}
