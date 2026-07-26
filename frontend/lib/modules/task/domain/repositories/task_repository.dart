import '../entities/task.dart';

/// Domain-level contract for task CRUD — presentation and the calendar
/// module depend only on this, never on ApiClient/package:http directly.
abstract class TaskRepository {
  Future<List<Task>> getTasks();

  Future<Task> createTask({
    required String name,
    required double weight,
    required DateTime startsOn,
    DateTime? endsOn,
  });

  Future<Task> updateTask({
    required String taskId,
    String? name,
    double? weight,
    DateTime? startsOn,
    DateTime? endsOn,
  });
}
