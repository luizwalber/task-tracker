import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/api_client.dart';
import 'package:frontend/modules/home/data/repositories/me_repository_impl.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient apiClient;
  late MeRepositoryImpl repository;

  setUp(() {
    apiClient = MockApiClient();
    repository = MeRepositoryImpl(apiClient);
  });

  test('returns the response body on a 200', () async {
    when(
      () => apiClient.get('/me'),
    ).thenAnswer((_) async => http.Response('{"id":"user-1"}', 200));

    final result = await repository.getMe();

    expect(result, '{"id":"user-1"}');
  });

  test('throws when the backend responds with a non-200 status', () async {
    when(
      () => apiClient.get('/me'),
    ).thenAnswer((_) async => http.Response('unauthorized', 401));

    expect(() => repository.getMe(), throwsA(isA<Exception>()));
  });
}
