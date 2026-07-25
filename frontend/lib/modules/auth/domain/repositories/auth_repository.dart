import '../entities/authenticated_user.dart';

/// Domain-level contract for authentication. The presentation layer (AuthBloc)
/// depends only on this — never on package:firebase_auth directly — so it can be
/// tested with a fake implementation, no Firebase plugin involved.
abstract class AuthRepository {
  Stream<AuthenticatedUser?> authStateChanges();

  Future<AuthenticatedUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<void> signOut();

  /// The Firebase ID token for the current session, attached as the Bearer
  /// token on every backend request. Null when there's no signed-in user.
  Future<String?> getIdToken();
}
