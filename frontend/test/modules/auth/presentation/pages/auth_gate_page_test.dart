import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/auth/domain/entities/authenticated_user.dart';
import 'package:frontend/modules/auth/domain/repositories/auth_repository.dart';
import 'package:frontend/modules/auth/presentation/bloc/auth_bloc.dart';
import 'package:frontend/modules/auth/presentation/pages/auth_gate_page.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

// Neither test below closes its AuthBloc — see the comment in
// login_page_test.dart: bloc.close() inside a testWidgets body hangs this
// Flutter/flutter_bloc combo when an event handler is still in flight, so
// these are throwaway test doubles, not resources leaked across tests.
void main() {
  testWidgets('shows the login form when there is no existing session', (
    tester,
  ) async {
    final authRepository = MockAuthRepository();
    when(
      () => authRepository.authStateChanges(),
    ).thenAnswer((_) => Stream.value(null));
    final bloc = AuthBloc(authRepository);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthBloc>.value(
          value: bloc,
          child: const AuthGatePage(),
        ),
      ),
    );

    // Session check in flight: no login form yet, just a loading state.
    expect(find.byKey(const Key('email-field')), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('email-field')), findsOneWidget);
  });

  testWidgets(
    'never shows the login form and reports authenticated when a session already exists',
    (tester) async {
      const user = AuthenticatedUser(uid: 'user-1');
      final authRepository = MockAuthRepository();
      when(
        () => authRepository.authStateChanges(),
      ).thenAnswer((_) => Stream.value(user));
      final bloc = AuthBloc(authRepository);

      var authenticatedCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>.value(
            value: bloc,
            child: AuthGatePage(
              onAuthenticated: (_) => authenticatedCalled = true,
            ),
          ),
        ),
      );
      // Not pumpAndSettle: the gate deliberately keeps an indeterminate
      // spinner animating while it waits to navigate away, so animations
      // never settle here — a couple of plain pumps let the stream/state
      // transition land instead.
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('email-field')), findsNothing);
      expect(authenticatedCalled, isTrue);
    },
  );
}
