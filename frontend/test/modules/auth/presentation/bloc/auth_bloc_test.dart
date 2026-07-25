import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/auth/domain/entities/authenticated_user.dart';
import 'package:frontend/modules/auth/domain/repositories/auth_repository.dart';
import 'package:frontend/modules/auth/presentation/bloc/auth_bloc.dart';
import 'package:frontend/modules/auth/presentation/bloc/auth_event.dart';
import 'package:frontend/modules/auth/presentation/bloc/auth_state.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository authRepository;

  setUp(() {
    authRepository = MockAuthRepository();
  });

  group('AuthBloc', () {
    const user = AuthenticatedUser(uid: 'user-1', email: 'user@example.com');

    blocTest<AuthBloc, AuthState>(
      'emits [AuthUnauthenticated] when the check finds no signed-in user',
      build: () {
        when(
          () => authRepository.authStateChanges(),
        ).thenAnswer((_) => Stream.value(null));
        return AuthBloc(authRepository);
      },
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      expect: () => [const AuthUnauthenticated()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthAuthenticated] when the check finds a signed-in user',
      build: () {
        when(
          () => authRepository.authStateChanges(),
        ).thenAnswer((_) => Stream.value(user));
        return AuthBloc(authRepository);
      },
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      expect: () => [const AuthAuthenticated(user)],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] on successful login',
      build: () {
        when(
          () => authRepository.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => user);
        return AuthBloc(authRepository);
      },
      act: (bloc) => bloc.add(
        const AuthLoginRequested(email: 'user@example.com', password: 'secret'),
      ),
      expect: () => [const AuthLoading(), const AuthAuthenticated(user)],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when login fails, without losing the ability to retry',
      build: () {
        when(
          () => authRepository.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(Exception('wrong-password'));
        return AuthBloc(authRepository);
      },
      act: (bloc) => bloc.add(
        const AuthLoginRequested(email: 'user@example.com', password: 'bad'),
      ),
      expect: () => [const AuthLoading(), isA<AuthError>()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthUnauthenticated] on logout',
      build: () {
        when(() => authRepository.signOut()).thenAnswer((_) async {});
        return AuthBloc(authRepository);
      },
      act: (bloc) => bloc.add(const AuthLogoutRequested()),
      expect: () => [const AuthUnauthenticated()],
      verify: (_) {
        verify(() => authRepository.signOut()).called(1);
      },
    );
  });
}
