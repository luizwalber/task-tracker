import 'dart:convert';

import '../../../../core/api_client.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';

class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<Task>> getTasks() async {
    final response = await _apiClient.get('/tasks');
    if (response.statusCode != 200) {
      throw Exception('GET /tasks failed (${response.statusCode}): ${response.body}');
    }
    final body = jsonDecode(response.body) as List<dynamic>;
    return body.map((json) => _fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<Task> createTask({
    required String name,
    required double weight,
    required DateTime startsOn,
    DateTime? endsOn,
  }) async {
    final response = await _apiClient.post('/tasks', {
      'name': name,
      'weight': weight,
      'startsOn': _isoDate(startsOn),
      if (endsOn != null) 'endsOn': _isoDate(endsOn),
    });
    if (response.statusCode != 201) {
      throw Exception('POST /tasks failed (${response.statusCode}): ${response.body}');
    }
    return _fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<Task> updateTask({
    required String taskId,
    String? name,
    double? weight,
    DateTime? startsOn,
    DateTime? endsOn,
  }) async {
    final response = await _apiClient.patch('/tasks/$taskId', {
      if (name != null) 'name': name,
      if (weight != null) 'weight': weight,
      if (startsOn != null) 'startsOn': _isoDate(startsOn),
      if (endsOn != null) 'endsOn': _isoDate(endsOn),
    });
    if (response.statusCode != 200) {
      throw Exception('PATCH /tasks/$taskId failed (${response.statusCode}): ${response.body}');
    }
    return _fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Task _fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      name: json['name'] as String,
      weight: (json['weight'] as num).toDouble(),
      startsOn: DateTime.parse(json['startsOn'] as String),
      endsOn: json['endsOn'] != null ? DateTime.parse(json['endsOn'] as String) : null,
    );
  }

  String _isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
