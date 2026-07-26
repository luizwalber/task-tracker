import 'dart:convert';

import '../../../../core/api_client.dart';
import '../../domain/entities/upsert_occurrence_result.dart';
import '../../domain/repositories/occurrence_repository.dart';

class OccurrenceRepositoryImpl implements OccurrenceRepository {
  OccurrenceRepositoryImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<UpsertOccurrenceResult> upsert({
    required String taskId,
    required DateTime date,
    required int percentage,
  }) async {
    final isoDate =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    final response = await _apiClient.put('/occurrences/$taskId/$isoDate', {
      'percentage': percentage,
    });
    if (response.statusCode != 200) {
      throw Exception(
        'PUT /occurrences/$taskId/$isoDate failed (${response.statusCode}): ${response.body}',
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final occurrence = body['occurrence'] as Map<String, dynamic>;
    return UpsertOccurrenceResult(
      taskId: occurrence['taskId'] as String,
      date: DateTime.parse(occurrence['date'] as String),
      percentage: occurrence['percentage'] as int,
      dayPerformance: (body['dayPerformance'] as num?)?.toDouble(),
    );
  }
}
