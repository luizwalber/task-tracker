import 'dart:convert';

import '../../../../core/api_client.dart';
import '../../domain/entities/calendar_day.dart';
import '../../domain/entities/calendar_month.dart';
import '../../domain/entities/occurrence_entry.dart';
import '../../domain/repositories/calendar_repository.dart';

class CalendarRepositoryImpl implements CalendarRepository {
  CalendarRepositoryImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<CalendarMonth> getMonth(int year, int month) async {
    final response = await _apiClient.get('/calendar/$year/$month');
    if (response.statusCode != 200) {
      throw Exception(
        'GET /calendar/$year/$month failed (${response.statusCode}): ${response.body}',
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final days = (body['days'] as List<dynamic>)
        .map((json) => _dayFromJson(json as Map<String, dynamic>))
        .toList();
    return CalendarMonth(
      serverToday: DateTime.parse(body['serverToday'] as String),
      days: days,
    );
  }

  CalendarDay _dayFromJson(Map<String, dynamic> json) {
    return CalendarDay(
      date: DateTime.parse(json['date'] as String),
      performance: (json['performance'] as num?)?.toDouble(),
      occurrences: (json['occurrences'] as List<dynamic>)
          .map(
            (o) => OccurrenceEntry(
              taskId: (o as Map<String, dynamic>)['taskId'] as String,
              percentage: o['percentage'] as int,
            ),
          )
          .toList(),
    );
  }
}
