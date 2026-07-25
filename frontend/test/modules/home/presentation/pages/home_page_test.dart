import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/modules/auth/domain/repositories/auth_repository.dart';
import 'package:frontend/modules/auth/presentation/bloc/auth_bloc.dart';
import 'package:frontend/modules/home/domain/repositories/me_repository.dart';
import 'package:frontend/modules/home/presentation/pages/home_page.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockMeRepository extends Mock implements MeRepository {}

void main() {
  late MockAuthRepository authRepository;
  late AuthBloc authBloc;

  setUp(() {
    authRepository = MockAuthRepository();
    authBloc = AuthBloc(authRepository);
  });

  Widget pump(MeRepository meRepository) {
    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: HomePage(meRepository: meRepository),
      ),
    );
  }

  testWidgets('golden path: shows the GET /me result once it resolves', (
    tester,
  ) async {
    final meRepository = MockMeRepository();
    when(() => meRepository.getMe()).thenAnswer((_) async => '{"id":"u1"}');

    await tester.pumpWidget(pump(meRepository));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.textContaining('{"id":"u1"}'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets(
    'shows the failure instead of spinning forever when GET /me fails',
    (tester) async {
      final meRepository = MockMeRepository();
      when(() => meRepository.getMe()).thenThrow(Exception('network down'));

      await tester.pumpWidget(pump(meRepository));
      await tester.pumpAndSettle();

      expect(find.textContaining('network down'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );
}
