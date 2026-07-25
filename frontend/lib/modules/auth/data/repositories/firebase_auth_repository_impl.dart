import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../domain/entities/authenticated_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_datasource.dart';

class FirebaseAuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDatasource _datasource;

  FirebaseAuthRepositoryImpl(this._datasource);

  @override
  Stream<AuthenticatedUser?> authStateChanges() {
    return _datasource.authStateChanges.map(_toDomain);
  }

  @override
  Future<AuthenticatedUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final credential = await _datasource.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _toDomain(credential.user)!;
  }

  @override
  Future<void> signOut() => _datasource.signOut();

  @override
  Future<String?> getIdToken() => _datasource.getIdToken();

  AuthenticatedUser? _toDomain(fb.User? user) {
    if (user == null) return null;
    return AuthenticatedUser(uid: user.uid, email: user.email);
  }
}
