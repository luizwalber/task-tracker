import '../../../../core/api_client.dart';
import '../../domain/repositories/me_repository.dart';

class MeRepositoryImpl implements MeRepository {
  MeRepositoryImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<String> getMe() async {
    final response = await _apiClient.get('/me');
    if (response.statusCode != 200) {
      throw Exception(
        'GET /me failed (${response.statusCode}): ${response.body}',
      );
    }
    return response.body;
  }
}
