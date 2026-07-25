import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/auth/domain/entities/authenticated_user.dart';
import 'package:frontend/modules/auth/domain/repositories/auth_repository.dart';
import 'package:frontend/modules/auth/presentation/bloc/auth_bloc.dart';
import 'package:frontend/modules/auth/presentation/bloc/auth_state.dart';
import 'package:frontend/modules/auth/presentation/pages/login_page.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  testWidgets(
    'golden path: filling the form and tapping login dispatches AuthLoginRequested',
    (tester) async {
      final authRepository = MockAuthRepository();
      // Deliberately never resolved: bloc.close() inside a testWidgets body
      // hangs this Flutter/flutter_bloc combo when an event handler is still
      // in flight, so this test doesn't close the bloc — it's a throwaway
      // test double, not a leaked resource across tests.
      when(
        () => authRepository.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) => Completer<AuthenticatedUser>().future);

      final bloc = AuthBloc(authRepository);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>.value(
            value: bloc,
            child: const LoginPage(),
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('email-field')),
        'user@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('password-field')),
        'secret123',
      );
      await tester.tap(find.byKey(const Key('login-button')));
      await tester.pump();

      expect(bloc.state, isA<AuthLoading>());
    },
  );
}
