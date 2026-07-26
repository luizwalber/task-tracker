import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/api_client.dart';
import 'package:frontend/modules/auth/domain/repositories/auth_repository.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late MockAuthRepository authRepository;
  late MockHttpClient httpClient;
  late ApiClient apiClient;

  setUpAll(() {
    registerFallbackValue(Uri.parse('https://fallback.example.com'));
  });

  setUp(() {
    authRepository = MockAuthRepository();
    httpClient = MockHttpClient();
    apiClient = ApiClient(
      authRepository,
      client: httpClient,
      baseUrl: 'https://api.example.com',
    );
  });

  test('attaches the current Firebase ID token as a Bearer header', () async {
    when(
      () => authRepository.getIdToken(),
    ).thenAnswer((_) async => 'the-token');
    when(
      () => httpClient.get(any(), headers: any(named: 'headers')),
    ).thenAnswer((_) async => http.Response('{}', 200));

    await apiClient.get('/me');

    final captured =
        verify(
              () => httpClient.get(
                Uri.parse('https://api.example.com/me'),
                headers: captureAny(named: 'headers'),
              ),
            ).captured.single
            as Map<String, String>;

    expect(captured['Authorization'], 'Bearer the-token');
  });

  test(
    'sends no Authorization header when there is no signed-in user',
    () async {
      when(() => authRepository.getIdToken()).thenAnswer((_) async => null);
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response('{}', 200));

      await apiClient.get('/me');

      final captured =
          verify(
                () => httpClient.get(
                  any(),
                  headers: captureAny(named: 'headers'),
                ),
              ).captured.single
              as Map<String, String>;

      expect(captured.containsKey('Authorization'), isFalse);
    },
  );

  test('put() sends a JSON-encoded body with a Bearer header', () async {
    when(
      () => authRepository.getIdToken(),
    ).thenAnswer((_) async => 'the-token');
    when(
      () => httpClient.put(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => http.Response('{}', 200));

    await apiClient.put('/occurrences/t1/2026-03-10', {'percentage': 70});

    final captured = verify(
      () => httpClient.put(
        Uri.parse('https://api.example.com/occurrences/t1/2026-03-10'),
        headers: captureAny(named: 'headers'),
        body: '{"percentage":70}',
      ),
    ).captured.single as Map<String, String>;

    expect(captured['Authorization'], 'Bearer the-token');
    expect(captured['Content-Type'], 'application/json');
  });
}
